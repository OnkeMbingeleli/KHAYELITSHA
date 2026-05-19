import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { LogOut, ShieldAlert, Plus, ArrowLeftRight } from "lucide-react";

export const Route = createFileRoute("/marshal")({
  head: () => ({ meta: [{ title: "Marshal — CODETA" }] }),
  component: MarshalPage,
});

type Rank = { id: string; name: string; code: string; branch_id: string };
type RouteRow = { id: string; name: string; code: string };
type LoadRow = {
  id: string; number_plate: string; route_id: string; rank_id: string;
  direction: "outbound" | "inbound"; seats_loaded: number; overload: boolean; recorded_at: string;
};

function MarshalPage() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  useEffect(() => { if (!loading && !user) navigate({ to: "/login" }); }, [loading, user, navigate]);

  const [ranks, setRanks] = useState<Rank[]>([]);
  const [routes, setRoutes] = useState<RouteRow[]>([]);
  const [rankId, setRankId] = useState<string>("");
  const [routeId, setRouteId] = useState<string>("");
  const [direction, setDirection] = useState<"outbound" | "inbound">("outbound");
  const [plate, setPlate] = useState("");
  const [overload, setOverload] = useState(false);
  const [comment, setComment] = useState("");
  const [busy, setBusy] = useState(false);
  const [todayLoads, setTodayLoads] = useState<LoadRow[]>([]);
  const [cap, setCap] = useState(10);

  // load picklists + cap
  useEffect(() => {
    (async () => {
      const [{ data: r }, { data: rt }, { data: s }] = await Promise.all([
        supabase.from("ranks").select("id,name,code,branch_id").order("code"),
        supabase.from("routes").select("id,name,code").order("name"),
        supabase.from("app_settings").select("value").eq("key", "daily_load_cap").maybeSingle(),
      ]);
      setRanks(r ?? []);
      setRoutes(rt ?? []);
      if (s?.value != null) setCap(Number(s.value));
      // restore last selection
      const last = JSON.parse(localStorage.getItem("codeta:marshal") || "{}");
      if (last.rankId) setRankId(last.rankId);
      if (last.routeId) setRouteId(last.routeId);
    })();
  }, []);

  useEffect(() => {
    localStorage.setItem("codeta:marshal", JSON.stringify({ rankId, routeId }));
  }, [rankId, routeId]);

  // today's loads at this rank/route
  async function refreshToday() {
    if (!rankId || !routeId) { setTodayLoads([]); return; }
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const { data } = await supabase
      .from("loads")
      .select("id,number_plate,route_id,rank_id,direction,seats_loaded,overload,recorded_at")
      .eq("rank_id", rankId).eq("route_id", routeId)
      .gte("recorded_at", startOfDay.toISOString())
      .order("recorded_at", { ascending: false })
      .limit(50);
    setTodayLoads((data ?? []) as LoadRow[]);
  }
  useEffect(() => { refreshToday(); }, [rankId, routeId]);

  // realtime
  useEffect(() => {
    if (!rankId || !routeId) return;
    const ch = supabase
      .channel(`loads-${rankId}-${routeId}`)
      .on("postgres_changes",
        { event: "INSERT", schema: "public", table: "loads", filter: `rank_id=eq.${rankId}` },
        () => refreshToday())
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [rankId, routeId]);

  const plateCount = useMemo(() => {
    const p = plate.trim().toUpperCase();
    if (!p) return 0;
    return todayLoads.filter((l) => l.number_plate === p).length;
  }, [plate, todayLoads]);

  async function submitLoad() {
    if (!user) return;
    const p = plate.trim().toUpperCase();
    if (!p) return toast.error("Number plate is required");
    if (!rankId || !routeId) return toast.error("Pick rank and route first");

    // check daily cap across all ranks/routes for this plate
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const { count } = await supabase
      .from("loads")
      .select("*", { count: "exact", head: true })
      .eq("number_plate", p)
      .gte("recorded_at", startOfDay.toISOString());
    if ((count ?? 0) >= cap) {
      toast.error(`${p} has reached the daily cap of ${cap} loads. Let others have a turn.`);
      return;
    }

    // try to look up vehicle
    const { data: veh } = await supabase
      .from("vehicles").select("id,seats,active")
      .eq("number_plate", p).maybeSingle();
    const seats = veh?.seats ?? 15;
    if (veh && veh.active === false) {
      toast.error("This vehicle is not active in the system.");
      return;
    }

    setBusy(true);
    const branch_id = ranks.find((r) => r.id === rankId)?.branch_id;
    if (!branch_id) { setBusy(false); return; }
    const { error } = await supabase.from("loads").insert({
      vehicle_id: veh?.id ?? null,
      number_plate: p,
      branch_id,
      rank_id: rankId,
      route_id: routeId,
      direction,
      seats_loaded: overload ? seats + 2 : seats,
      overload,
      comment: comment.trim() || null,
      marshal_id: user.id,
    });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success(`${p} — load #${(count ?? 0) + 1} today`);
    setPlate(""); setOverload(false); setComment("");
  }

  const rank = ranks.find((r) => r.id === rankId);
  const route = routes.find((r) => r.id === routeId);

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="px-4 py-3 border-b border-border flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">C</div>
          <span className="font-semibold">CODETA · Marshal</span>
        </Link>
        <Button size="sm" variant="ghost" onClick={async () => { await supabase.auth.signOut(); navigate({ to: "/" }); }}>
          <LogOut className="h-4 w-4" />
        </Button>
      </header>

      <main className="max-w-md mx-auto px-4 py-5 space-y-5">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <Label>Rank / Spot</Label>
            <Select value={rankId} onValueChange={setRankId}>
              <SelectTrigger><SelectValue placeholder="Pick rank" /></SelectTrigger>
              <SelectContent>{ranks.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
            </Select>
          </div>
          <div>
            <Label>Route</Label>
            <Select value={routeId} onValueChange={setRouteId}>
              <SelectTrigger><SelectValue placeholder="Pick route" /></SelectTrigger>
              <SelectContent>{routes.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
            </Select>
          </div>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 space-y-3">
          <div className="flex items-center justify-between">
            <Label className="text-base">Number plate</Label>
            <button type="button" onClick={() => setDirection(d => d === "outbound" ? "inbound" : "outbound")}
              className="text-xs px-2 py-1 rounded-md bg-secondary text-secondary-foreground inline-flex items-center gap-1">
              <ArrowLeftRight className="h-3 w-3" />
              {direction === "outbound" ? "Township → Town" : "Town → Township"}
            </button>
          </div>
          <Input
            inputMode="text" autoCapitalize="characters" autoComplete="off"
            placeholder="e.g. PW722 WP"
            className="text-2xl font-mono tracking-wider h-14"
            value={plate}
            onChange={(e) => setPlate(e.target.value.toUpperCase())}
          />
          {plate && (
            <p className="text-xs text-muted-foreground">
              {plateCount > 0
                ? `${plate.trim()} has ${plateCount} load(s) here today`
                : `First load for ${plate.trim()} at this rank today`}
            </p>
          )}

          <div className="flex items-center justify-between pt-1">
            <div>
              <Label className="text-sm">Overload</Label>
              <p className="text-xs text-muted-foreground">Mark if more than the legal seats.</p>
            </div>
            <Switch checked={overload} onCheckedChange={setOverload} />
          </div>

          <Textarea
            placeholder="Optional comment (driver behaviour, vehicle issue…)"
            value={comment} onChange={(e) => setComment(e.target.value)}
            className="min-h-16"
          />

          <Button onClick={submitLoad} disabled={busy || !plate.trim() || !rankId || !routeId} className="w-full h-12 text-base">
            <Plus className="h-5 w-5 mr-1" />
            {busy ? "Saving…" : "Submit load"}
          </Button>
        </div>

        <section>
          <div className="flex items-center justify-between mb-2">
            <h2 className="font-semibold">Today at {rank?.name ?? "—"} · {route?.name ?? "—"}</h2>
            <span className="text-xs text-muted-foreground">{todayLoads.length} loads</span>
          </div>
          <div className="space-y-2">
            {todayLoads.length === 0 && (
              <p className="text-sm text-muted-foreground">No loads logged here yet today.</p>
            )}
            {todayLoads.map((l) => (
              <div key={l.id} className="flex items-center justify-between rounded-lg border border-border bg-card px-3 py-2">
                <div>
                  <p className="font-mono font-semibold">{l.number_plate}</p>
                  <p className="text-xs text-muted-foreground">
                    {new Date(l.recorded_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                    {" · "}{l.direction === "outbound" ? "→ Town" : "← Town"}
                    {l.overload && <span className="ml-1 text-destructive inline-flex items-center"><ShieldAlert className="h-3 w-3 mr-0.5" />overload</span>}
                  </p>
                </div>
                <span className="text-xs text-muted-foreground">{l.seats_loaded} seats</span>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}