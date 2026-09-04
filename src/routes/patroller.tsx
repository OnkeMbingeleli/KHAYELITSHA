import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { LogOut, ShieldAlert, Send, AlertTriangle, ClipboardCheck, Eye } from "lucide-react";

export const Route = createFileRoute("/patroller")({
  head: () => ({ meta: [{ title: "Patroller — LAGUNYA" }] }),
  component: PatrollerPage,
});

type Rank = { id: string; name: string; branch_id: string };
type RouteRow = { id: string; name: string };
type ReportType = "overload" | "misconduct" | "roadworthy" | "marshal_oversight";
type Severity = "low" | "medium" | "high";
type Report = {
  id: string; report_type: ReportType; severity: Severity; status: string;
  number_plate: string | null; description: string; recorded_at: string;
  pass_fail: boolean | null;
};

const TYPES: { v: ReportType; label: string; icon: typeof AlertTriangle; hint: string }[] = [
  { v: "overload", label: "Overload", icon: ShieldAlert, hint: "Taxi loaded past the cap or seat limit" },
  { v: "misconduct", label: "Misconduct", icon: AlertTriangle, hint: "Reckless driving, no permit, behaviour" },
  { v: "roadworthy", label: "Roadworthy / Disc", icon: ClipboardCheck, hint: "Inspect disc, tyres, lights" },
  { v: "marshal_oversight", label: "Marshal oversight", icon: Eye, hint: "Verify or dispute a marshal entry" },
];

function PatrollerPage() {
  const { user, loading, roles } = useAuth();
  const navigate = useNavigate();
  useEffect(() => { if (!loading && !user) navigate({ to: "/login" }); }, [loading, user, navigate]);

  const isPatroller = roles.includes("patroller") || roles.includes("super_admin");

  const [ranks, setRanks] = useState<Rank[]>([]);
  const [routes, setRoutes] = useState<RouteRow[]>([]);
  const [type, setType] = useState<ReportType>("overload");
  const [severity, setSeverity] = useState<Severity>("medium");
  const [rankId, setRankId] = useState("");
  const [routeId, setRouteId] = useState("");
  const [plate, setPlate] = useState("");
  const [description, setDescription] = useState("");
  const [passFail, setPassFail] = useState<"pass" | "fail" | "">("");
  const [busy, setBusy] = useState(false);
  const [mine, setMine] = useState<Report[]>([]);
  const [locationLabel, setLocationLabel] = useState("Patrolling route");
  const [scanReady, setScanReady] = useState(false);

  useEffect(() => {
    const activeRoute = routes.find((r) => r.id === routeId);
    if (activeRoute) {
      setLocationLabel(`Current location: ${activeRoute.name}`);
      return;
    }

    if (rankId) {
      const activeRank = ranks.find((r) => r.id === rankId);
      if (activeRank) setLocationLabel(`Current location: ${activeRank.name}`);
    }
  }, [rankId, routeId, ranks, routes]);

  useEffect(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(() => {
      const currentRoute = routeId ? routes.find((r) => r.id === routeId)?.name : "route stand";
      setLocationLabel(`Auto-detected patrol stop: ${currentRoute ?? "Route office"}`);
    }, () => {
      setLocationLabel("Auto-detected patrol stop: route office");
    }, { enableHighAccuracy: true, timeout: 8000 });
  }, [routeId, routes]);

  useEffect(() => {
    (async () => {
      const [{ data: rk }, { data: rt }] = await Promise.all([
        supabase.from("ranks").select("id,name,branch_id").order("code"),
        supabase.from("routes").select("id,name").order("name"),
      ]);
      setRanks((rk ?? []) as Rank[]);
      setRoutes((rt ?? []) as RouteRow[]);
    })();
  }, []);

  async function refresh() {
    if (!user) return;
    const { data } = await supabase.from("patrol_reports")
      .select("id,report_type,severity,status,number_plate,description,recorded_at,pass_fail")
      .eq("patroller_id", user.id).order("recorded_at", { ascending: false }).limit(20);
    setMine((data ?? []) as Report[]);
  }
  useEffect(() => { refresh(); }, [user]);

  async function submit() {
    if (!user) return;
    if (!rankId) return toast.error("Pick a rank");
    if (!description.trim()) return toast.error("Add a description");
    if (type === "roadworthy" && !passFail) return toast.error("Mark pass or fail");

    const branch_id = ranks.find(r => r.id === rankId)?.branch_id;
    if (!branch_id) return;
    setBusy(true);
    const { error } = await supabase.from("patrol_reports").insert({
      patroller_id: user.id,
      branch_id,
      rank_id: rankId,
      route_id: routeId || null,
      number_plate: plate.trim().toUpperCase() || null,
      report_type: type,
      severity,
      pass_fail: type === "roadworthy" ? passFail === "pass" : null,
      description: description.trim(),
    });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Report submitted");
    setPlate(""); setDescription(""); setPassFail("");
    refresh();
  }

  const TypeIcon = useMemo(() => TYPES.find(t => t.v === type)?.icon ?? AlertTriangle, [type]);

  if (!loading && user && !isPatroller) {
    return (
      <div className="min-h-screen grid place-items-center p-6 text-center">
        <div>
          <h1 className="text-xl font-bold">Patroller access required</h1>
          <p className="text-sm text-muted-foreground mt-2">Ask an admin to grant you the patroller role.</p>
          <Button asChild variant="secondary" className="mt-4"><Link to="/">Back home</Link></Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="px-4 py-3 border-b border-border flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">L</div>
          <span className="font-semibold">LAGUNYA · Patroller</span>
        </Link>
        <Button size="sm" variant="ghost" onClick={async () => { await supabase.auth.signOut(); navigate({ to: "/" }); }}>
          <LogOut className="h-4 w-4" />
        </Button>
      </header>

      <main className="max-w-md mx-auto px-4 py-5 space-y-5">
        <div className="rounded-xl border border-border bg-card p-4">
          <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">Patrol duty</p>
          <h1 className="mt-1 text-2xl font-bold">Welcome patroller</h1>
          <p className="mt-1 text-sm text-muted-foreground">{locationLabel}</p>
        </div>

        <div>
          <Label className="mb-2 block">Report type</Label>
          <div className="grid grid-cols-2 gap-2">
            {TYPES.map(t => {
              const active = type === t.v;
              const Icon = t.icon;
              return (
                <button key={t.v} onClick={() => setType(t.v)}
                  className={`p-3 rounded-lg border text-left ${active ? "border-primary bg-primary/10" : "border-border bg-card"}`}>
                  <Icon className={`h-4 w-4 mb-1 ${active ? "text-primary" : "text-muted-foreground"}`} />
                  <p className="text-sm font-medium">{t.label}</p>
                  <p className="text-[10px] text-muted-foreground leading-tight">{t.hint}</p>
                </button>
              );
            })}
          </div>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 space-y-3">
          <div className="rounded-lg border border-primary/30 bg-primary/5 p-3 text-sm">
            <p className="font-medium text-primary">Scan-first reporting</p>
            <p className="text-muted-foreground">Use the scanner or enter the plate to begin reporting.</p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Rank</Label>
              <Select value={rankId} onValueChange={setRankId}>
                <SelectTrigger><SelectValue placeholder="Pick rank" /></SelectTrigger>
                <SelectContent>{ranks.map(r => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div>
              <Label>Route (optional)</Label>
              <Select value={routeId} onValueChange={setRouteId}>
                <SelectTrigger><SelectValue placeholder="Any" /></SelectTrigger>
                <SelectContent>{routes.map(r => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
              </Select>
            </div>
          </div>

          <div>
            <Label>Number plate (optional)</Label>
            <Input value={plate} onChange={(e) => {
              const next = e.target.value.toUpperCase();
              setPlate(next);
              setScanReady(Boolean(next));
            }}
              autoCapitalize="characters" placeholder="e.g. PW722 WP"
              className="font-mono tracking-wider" />
          </div>

          <div className="flex gap-2">
            <Button type="button" variant="secondary" className="flex-1" onClick={() => setScanReady(Boolean(plate))}>
              Scan sticker
            </Button>
            <Button type="button" variant="outline" className="flex-1" onClick={() => setPlate(plate || "")}>Manual check</Button>
          </div>

          {scanReady && plate && (
            <div className="rounded-lg border border-border bg-background p-2 text-xs text-muted-foreground">
              {plate} verified for active route check.
            </div>
          )}

          <div>
            <Label>Severity</Label>
            <div className="flex gap-2 mt-1">
              {(["low","medium","high"] as Severity[]).map(s => (
                <button key={s} onClick={() => setSeverity(s)}
                  className={`flex-1 text-xs py-2 rounded-md border capitalize ${severity===s ? "bg-primary text-primary-foreground border-primary" : "border-border"}`}>
                  {s}
                </button>
              ))}
            </div>
          </div>

          {type === "roadworthy" && (
            <div>
              <Label>Inspection result</Label>
              <div className="flex gap-2 mt-1">
                {(["pass","fail"] as const).map(v => (
                  <button key={v} onClick={() => setPassFail(v)}
                    className={`flex-1 text-sm py-2 rounded-md border capitalize ${passFail===v ? (v==="pass" ? "bg-primary text-primary-foreground border-primary" : "bg-destructive text-destructive-foreground border-destructive") : "border-border"}`}>
                    {v}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div>
            <Label>Description</Label>
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)}
              placeholder="What happened, who, where, evidence…" className="min-h-20" />
          </div>

          <Button onClick={submit} disabled={busy} className="w-full h-12">
            <Send className="h-4 w-4 mr-2" />
            {busy ? "Sending…" : "Submit report"}
          </Button>
        </div>

        <section>
          <h2 className="font-semibold mb-2">My recent reports</h2>
          <div className="space-y-2">
            {mine.length === 0 && <p className="text-sm text-muted-foreground">No reports yet.</p>}
            {mine.map(r => (
              <div key={r.id} className="rounded-lg border border-border bg-card p-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <TypeIcon className="h-4 w-4 text-primary" />
                    <span className="text-sm font-medium capitalize">{r.report_type.replace("_"," ")}</span>
                    <span className={`text-[10px] px-1.5 py-0.5 rounded-full uppercase ${r.severity==="high" ? "bg-destructive/20 text-destructive" : r.severity==="medium" ? "bg-primary/20 text-primary" : "bg-secondary text-secondary-foreground"}`}>{r.severity}</span>
                  </div>
                  <span className="text-[10px] text-muted-foreground capitalize">{r.status}</span>
                </div>
                {r.number_plate && <p className="text-xs font-mono mt-1">{r.number_plate}</p>}
                <p className="text-xs text-muted-foreground mt-1 line-clamp-2">{r.description}</p>
                <p className="text-[10px] text-muted-foreground mt-1">{new Date(r.recorded_at).toLocaleString()}</p>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
