import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import {
  adminListOffices, adminCreateOffice, adminUpdateOffice, adminDeleteOffice, adminKickSession,
} from "@/lib/subhead.functions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { Trash2, KeyRound, X } from "lucide-react";

export const Route = createFileRoute("/admin/subheads")({
  component: AdminSubheads,
});

type Office = {
  id: string; route_id: string; branch_id: string;
  name: string; town: string | null; lat: number; lng: number;
};
type Route = { id: string; name: string; code: string; branch_id: string };
type Sess = { id: string; office_id: string; user_agent: string | null; last_seen_at: string };

function AdminSubheads() {
  const [offices, setOffices] = useState<Office[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [sessions, setSessions] = useState<Sess[]>([]);
  const [loading, setLoading] = useState(true);

  const list = useServerFn(adminListOffices);
  const create = useServerFn(adminCreateOffice);
  const update = useServerFn(adminUpdateOffice);
  const del = useServerFn(adminDeleteOffice);
  const kick = useServerFn(adminKickSession);

  const [routeId, setRouteId] = useState("");
  const [name, setName] = useState("");
  const [town, setTown] = useState("");
  const [lat, setLat] = useState("-26.2041");
  const [lng, setLng] = useState("28.0473");
  const [code, setCode] = useState("");

  const refresh = async () => {
    setLoading(true);
    try {
      const r = await list();
      setOffices(r.offices as any);
      setRoutes(r.routes as any);
      setSessions(r.sessions as any);
    } finally { setLoading(false); }
  };

  useEffect(() => { refresh(); }, []);

  const usedRouteIds = new Set(offices.map((o) => o.route_id));
  const availableRoutes = routes.filter((r) => !usedRouteIds.has(r.id));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const r = routes.find((x) => x.id === routeId);
    if (!r) { toast.error("Pick a route"); return; }
    try {
      await create({ data: {
        route_id: routeId, branch_id: r.branch_id, name, town: town || undefined,
        lat: Number(lat), lng: Number(lng), code,
      }});
      toast.success("Office created. Share the access code now — it can't be shown again.");
      setRouteId(""); setName(""); setTown(""); setCode("");
      refresh();
    } catch (err: any) { toast.error(err?.message ?? "Failed"); }
  };

  const resetCode = async (id: string) => {
    const c = window.prompt("New access code (4–32 chars). All current devices will be signed out.");
    if (!c || c.length < 4) return;
    try {
      await update({ data: { id, code: c } });
      toast.success("Code updated. Devices signed out.");
      refresh();
    } catch (err: any) { toast.error(err?.message ?? "Failed"); }
  };

  const remove = async (id: string) => {
    if (!window.confirm("Delete this subhead office?")) return;
    await del({ data: { id } });
    toast.success("Deleted");
    refresh();
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Subhead offices</h1>
        <p className="text-sm text-muted-foreground">One per route. Shared code, max 2 devices each.</p>
      </div>

      <form onSubmit={submit} className="p-4 rounded-xl border border-border bg-card grid gap-3 md:grid-cols-2">
        <div className="space-y-1">
          <Label>Route</Label>
          <Select value={routeId} onValueChange={setRouteId}>
            <SelectTrigger><SelectValue placeholder="Pick a route" /></SelectTrigger>
            <SelectContent>
              {availableRoutes.map((r) => (
                <SelectItem key={r.id} value={r.id}>{r.code} · {r.name}</SelectItem>
              ))}
              {availableRoutes.length === 0 && <div className="px-3 py-2 text-sm text-muted-foreground">All routes have offices</div>}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Office name</Label>
          <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Pretoria Subhead" required />
        </div>
        <div className="space-y-1">
          <Label>Town (optional)</Label>
          <Input value={town} onChange={(e) => setTown(e.target.value)} placeholder="Pretoria" />
        </div>
        <div className="space-y-1">
          <Label>Access code</Label>
          <Input value={code} onChange={(e) => setCode(e.target.value)} minLength={4} maxLength={32} required placeholder="Shared password" />
        </div>
        <div className="space-y-1">
          <Label>Latitude</Label>
          <Input value={lat} onChange={(e) => setLat(e.target.value)} required />
        </div>
        <div className="space-y-1">
          <Label>Longitude</Label>
          <Input value={lng} onChange={(e) => setLng(e.target.value)} required />
        </div>
        <div className="md:col-span-2 text-xs text-muted-foreground">
          Tip: Open Google Maps, right-click the destination, copy the coordinates, paste them here.
        </div>
        <div className="md:col-span-2"><Button type="submit">Create office</Button></div>
      </form>

      <div className="rounded-xl border border-border bg-card divide-y divide-border">
        {loading && <div className="p-4 text-sm text-muted-foreground">Loading…</div>}
        {!loading && offices.length === 0 && <div className="p-4 text-sm text-muted-foreground">No offices yet.</div>}
        {offices.map((o) => {
          const r = routes.find((x) => x.id === o.route_id);
          const sess = sessions.filter((s) => s.office_id === o.id);
          return (
            <div key={o.id} className="p-4 flex flex-col md:flex-row md:items-center gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{o.name} {o.town && <span className="text-muted-foreground font-normal">· {o.town}</span>}</div>
                <div className="text-xs text-muted-foreground">Route: {r?.code ?? "?"} {r?.name ?? ""} · {o.lat.toFixed(4)}, {o.lng.toFixed(4)}</div>
                <div className="text-xs mt-1">Active devices: <b>{sess.length}</b> / 2</div>
                {sess.length > 0 && (
                  <ul className="text-xs text-muted-foreground mt-1 space-y-1">
                    {sess.map((s) => (
                      <li key={s.id} className="flex items-center gap-2">
                        <span className="truncate flex-1">{(s.user_agent ?? "Unknown device").slice(0, 60)}</span>
                        <span>last seen {new Date(s.last_seen_at).toLocaleTimeString()}</span>
                        <button onClick={async () => { await kick({ data: { id: s.id } }); refresh(); }} className="text-destructive hover:underline">
                          <X className="h-3 w-3 inline" /> kick
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant="secondary" onClick={() => resetCode(o.id)}>
                  <KeyRound className="h-4 w-4 mr-1" /> Reset code
                </Button>
                <Button size="sm" variant="destructive" onClick={() => remove(o.id)}>
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}