import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useMemo, useRef, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import {
  listOfficesPublic,
  subheadLogin,
  subheadHeartbeat,
  subheadLogout,
  getSubheadMapData,
} from "@/lib/subhead.functions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";
import { LogOut, MapPin } from "lucide-react";
import { MapContainer, TileLayer, CircleMarker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import { supabase } from "@/integrations/supabase/client";

const STORAGE_KEY = "lagunya.subhead.session";

type Stored = { device_token: string; office_id: string };

export const Route = createFileRoute("/subhead")({
  head: () => ({ meta: [{ title: "Subhead Office — LAGUNYA" }] }),
  component: SubheadPage,
});

function loadStored(): Stored | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
}

function SubheadPage() {
  const [stored, setStored] = useState<Stored | null>(null);
  const [bootChecked, setBootChecked] = useState(false);
  const heartbeat = useServerFn(subheadHeartbeat);

  useEffect(() => {
    const s = loadStored();
    if (!s) { setBootChecked(true); return; }
    heartbeat({ data: { device_token: s.device_token } }).then((r) => {
      if (r.ok) setStored(s);
      else localStorage.removeItem(STORAGE_KEY);
      setBootChecked(true);
    }).catch(() => setBootChecked(true));
  }, [heartbeat]);

  if (!bootChecked) {
    return <div className="min-h-screen grid place-items-center text-muted-foreground">Loading…</div>;
  }

  if (!stored) {
    return <SubheadLogin onLoggedIn={(s) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
      setStored(s);
    }} />;
  }

  return <SubheadDashboard stored={stored} onLogout={() => {
    localStorage.removeItem(STORAGE_KEY);
    setStored(null);
  }} />;
}

function SubheadLogin({ onLoggedIn }: { onLoggedIn: (s: Stored) => void }) {
  const [offices, setOffices] = useState<Array<{ id: string; name: string; town: string | null }>>([]);
  const [officeId, setOfficeId] = useState("");
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const list = useServerFn(listOfficesPublic);
  const login = useServerFn(subheadLogin);

  useEffect(() => {
    list().then((r) => setOffices(r.offices as any)).catch(() => {});
  }, [list]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!officeId || !code) return;
    setBusy(true);
    try {
      const r = await login({
        data: { office_id: officeId, code, user_agent: navigator.userAgent.slice(0, 250) },
      });
      if (!r.ok) { toast.error(r.reason); return; }
      onLoggedIn({ device_token: r.device_token, office_id: r.office_id });
    } catch (err: any) {
      toast.error(err?.message ?? "Sign-in failed");
    } finally { setBusy(false); }
  };

  return (
    <div className="min-h-screen grid place-items-center p-4 bg-background text-foreground">
      <form onSubmit={submit} className="w-full max-w-sm p-6 rounded-xl border border-border bg-card space-y-4">
        <div className="text-center">
          <div className="mx-auto h-10 w-10 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">L</div>
          <h1 className="mt-3 text-xl font-bold">Subhead Office Login</h1>
          <p className="text-sm text-muted-foreground">View-only live map for your route.</p>
        </div>
        <div className="space-y-2">
          <Label>Subhead office</Label>
          <Select value={officeId} onValueChange={setOfficeId}>
            <SelectTrigger><SelectValue placeholder="Choose your office" /></SelectTrigger>
            <SelectContent>
              {offices.map((o) => (
                <SelectItem key={o.id} value={o.id}>
                  {o.name}{o.town ? ` · ${o.town}` : ""}
                </SelectItem>
              ))}
              {offices.length === 0 && <div className="px-3 py-2 text-sm text-muted-foreground">No offices yet</div>}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Access code</Label>
          <Input type="password" value={code} onChange={(e) => setCode(e.target.value)} placeholder="Shared code" />
        </div>
        <Button type="submit" className="w-full" disabled={busy || !officeId || !code}>
          {busy ? "Signing in…" : "Sign in"}
        </Button>
        <p className="text-xs text-muted-foreground text-center">Max 2 devices per office.</p>
      </form>
    </div>
  );
}

type OfficeRow = {
  id: string; name: string; town: string | null; lat: number; lng: number;
  route_id: string; branch_id: string;
  today_count: number; last_at: string | null; last_plate: string | null; overloads: number;
};

function statusOf(lastAt: string | null): "green" | "orange" | "red" {
  if (!lastAt) return "red";
  const ageMin = (Date.now() - new Date(lastAt).getTime()) / 60000;
  if (ageMin <= 15) return "green";
  if (ageMin <= 60) return "orange";
  return "red";
}

const COLOR = { green: "#16a34a", orange: "#f59e0b", red: "#dc2626" } as const;

function SubheadDashboard({ stored, onLogout }: { stored: Stored; onLogout: () => void }) {
  const [data, setData] = useState<{ offices: OfficeRow[]; my_office_id: string } | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [now, setNow] = useState<Date>(new Date());
  const fetchMap = useServerFn(getSubheadMapData);
  const heartbeat = useServerFn(subheadHeartbeat);
  const logout = useServerFn(subheadLogout);
  const tickRef = useRef<number>(0);

  const refresh = useMemo(() => async () => {
    try {
      const r = await fetchMap({ data: { device_token: stored.device_token } });
      if (!r.ok) { setErr(r.reason); return; }
      setData({ offices: r.offices as OfficeRow[], my_office_id: r.my_office_id });
      setErr(null);
    } catch (e: any) { setErr(e?.message ?? "Failed to load"); }
  }, [fetchMap, stored.device_token]);

  useEffect(() => {
    refresh();
    const dataTimer = window.setInterval(refresh, 15000);
    const hbTimer = window.setInterval(() => {
      heartbeat({ data: { device_token: stored.device_token } }).catch(() => {});
    }, 60000);
    tickRef.current = window.setInterval(() => {
      // ticks the clock + forces recolour as time passes
      setNow(new Date());
      setData((d) => d ? { ...d } : d);
    }, 1000);
    const ch = supabase
      .channel("subhead-loads")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "loads" }, () => refresh())
      .subscribe();
    return () => {
      clearInterval(dataTimer); clearInterval(hbTimer); clearInterval(tickRef.current);
      supabase.removeChannel(ch);
    };
  }, [refresh, heartbeat, stored.device_token]);

  if (err) {
    return (
      <div className="min-h-screen grid place-items-center p-6 text-center">
        <div>
          <p className="text-destructive font-medium">{err}</p>
          <Button className="mt-4" onClick={async () => { await logout({ data: { device_token: stored.device_token } }).catch(() => {}); onLogout(); }}>
            Back to login
          </Button>
        </div>
      </div>
    );
  }

  const offices = data?.offices ?? [];
  const me = offices.find((o) => o.id === data?.my_office_id);
  const center: [number, number] = me ? [me.lat, me.lng]
    : offices[0] ? [offices[0].lat, offices[0].lng] : [-26.2041, 28.0473];

  const counts = offices.reduce((acc, o) => { acc[statusOf(o.last_at)]++; return acc; }, { green: 0, orange: 0, red: 0 });

  return (
    <div className="min-h-screen flex flex-col bg-background text-foreground">
      <header className="px-4 py-3 border-b border-border flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">L</div>
          <div>
            <div className="font-semibold leading-tight">{me?.name ?? "Subhead Office"}</div>
            <div className="text-xs text-muted-foreground">{me?.town ?? "Live route activity"}</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className="text-right">
            <div className="font-mono text-sm font-semibold tabular-nums">
              {now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
            </div>
            <div className="text-[10px] text-muted-foreground">
              {now.toLocaleDateString([], { weekday: "short", day: "2-digit", month: "short" })}
            </div>
          </div>
          <Button size="sm" variant="ghost" onClick={async () => {
            await logout({ data: { device_token: stored.device_token } }).catch(() => {});
            onLogout();
          }}>
            <LogOut className="h-4 w-4 mr-1" />Sign out
          </Button>
        </div>
      </header>

      <div className="px-4 py-3 grid grid-cols-3 gap-2 text-center text-sm">
        <div className="rounded-lg border border-border p-2"><div className="font-bold" style={{ color: COLOR.green }}>{counts.green}</div><div className="text-xs text-muted-foreground">Active</div></div>
        <div className="rounded-lg border border-border p-2"><div className="font-bold" style={{ color: COLOR.orange }}>{counts.orange}</div><div className="text-xs text-muted-foreground">Quiet</div></div>
        <div className="rounded-lg border border-border p-2"><div className="font-bold" style={{ color: COLOR.red }}>{counts.red}</div><div className="text-xs text-muted-foreground">Idle</div></div>
      </div>

      <div className="flex-1 min-h-[400px] mx-4 mb-4 rounded-xl overflow-hidden border border-border">
        <MapContainer center={center} zoom={11} style={{ height: "100%", width: "100%", minHeight: 400 }}>
          <TileLayer
            attribution='&copy; OpenStreetMap'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {offices.map((o) => {
            const s = statusOf(o.last_at);
            return (
              <CircleMarker
                key={o.id}
                center={[o.lat, o.lng]}
                radius={o.id === data?.my_office_id ? 14 : 10}
                pathOptions={{ color: COLOR[s], fillColor: COLOR[s], fillOpacity: 0.8, weight: o.id === data?.my_office_id ? 3 : 2 }}
              >
                <Popup>
                  <div className="text-sm">
                    <div className="font-semibold">{o.name}</div>
                    {o.town && <div className="text-xs text-muted-foreground">{o.town}</div>}
                    <div className="mt-1">Today: <b>{o.today_count}</b> loads</div>
                    <div>Overloads: {o.overloads}</div>
                    <div>Last: {o.last_at ? new Date(o.last_at).toLocaleTimeString() : "—"}</div>
                    {o.last_plate && <div>Plate: {o.last_plate}</div>}
                  </div>
                </Popup>
              </CircleMarker>
            );
          })}
        </MapContainer>
      </div>

      <div className="px-4 pb-4 flex items-center justify-center gap-4 text-xs text-muted-foreground">
        <span className="flex items-center gap-1"><MapPin className="h-3 w-3" style={{ color: COLOR.green }} /> Active &lt;15m</span>
        <span className="flex items-center gap-1"><MapPin className="h-3 w-3" style={{ color: COLOR.orange }} /> Quiet &lt;1h</span>
        <span className="flex items-center gap-1"><MapPin className="h-3 w-3" style={{ color: COLOR.red }} /> Idle</span>
      </div>
    </div>
  );
}