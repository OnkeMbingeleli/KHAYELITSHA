import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { TrendingUp, MapPin, Truck, ArrowUpRight } from "lucide-react";

export const Route = createFileRoute("/admin/")({
  component: AdminDashboard,
});

type Load = {
  id: string; number_plate: string; rank_id: string; route_id: string;
  direction: "outbound" | "inbound"; recorded_at: string; overload: boolean;
};

function AdminDashboard() {
  const [loads, setLoads] = useState<Load[]>([]);
  const [ranks, setRanks] = useState<Record<string, string>>({});
  const [routes, setRoutes] = useState<Record<string, string>>({});

  async function refresh() {
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const { data } = await supabase
      .from("loads")
      .select("id,number_plate,rank_id,route_id,direction,recorded_at,overload")
      .gte("recorded_at", startOfDay.toISOString())
      .order("recorded_at", { ascending: false })
      .limit(500);
    setLoads((data ?? []) as Load[]);
  }

  useEffect(() => {
    (async () => {
      const [{ data: r }, { data: rt }] = await Promise.all([
        supabase.from("ranks").select("id,name"),
        supabase.from("routes").select("id,name"),
      ]);
      setRanks(Object.fromEntries((r ?? []).map((x) => [x.id, x.name])));
      setRoutes(Object.fromEntries((rt ?? []).map((x) => [x.id, x.name])));
      refresh();
    })();
    const ch = supabase.channel("admin-loads")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "loads" }, () => refresh())
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, []);

  const byRank = useMemo(() => groupCount(loads, (l) => l.rank_id), [loads]);
  const byRoute = useMemo(() => groupCount(loads, (l) => l.route_id), [loads]);
  const outbound = loads.filter((l) => l.direction === "outbound").length;
  const inbound = loads.filter((l) => l.direction === "inbound").length;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Today's movement</h1>

      <div className="grid sm:grid-cols-3 gap-3">
        <Stat icon={Truck} label="Total loads today" value={loads.length} />
        <Stat icon={ArrowUpRight} label="Township → Town" value={outbound} />
        <Stat icon={TrendingUp} label="Town → Township" value={inbound} />
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <Panel title="Loads by rank" icon={MapPin}>
          <RankList items={byRank} labels={ranks} />
        </Panel>
        <Panel title="Loads by route" icon={TrendingUp}>
          <RankList items={byRoute} labels={routes} />
        </Panel>
      </div>

      <Panel title="Live feed" icon={Truck}>
        <div className="space-y-2 max-h-96 overflow-auto">
          {loads.slice(0, 30).map((l) => (
            <div key={l.id} className="flex items-center justify-between rounded-lg border border-border bg-card px-3 py-2">
              <div>
                <p className="font-mono font-semibold">{l.number_plate}</p>
                <p className="text-xs text-muted-foreground">
                  {ranks[l.rank_id] ?? "—"} · {routes[l.route_id] ?? "—"} · {l.direction === "outbound" ? "→ Town" : "← Town"}
                </p>
              </div>
              <span className="text-xs text-muted-foreground">
                {new Date(l.recorded_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
              </span>
            </div>
          ))}
          {loads.length === 0 && <p className="text-sm text-muted-foreground">No loads logged yet today.</p>}
        </div>
      </Panel>
    </div>
  );
}

function Stat({ icon: Icon, label, value }: { icon: React.ComponentType<{ className?: string }>; label: string; value: number }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <div className="flex items-center gap-2 text-muted-foreground text-sm"><Icon className="h-4 w-4" />{label}</div>
      <p className="text-3xl font-bold mt-1">{value}</p>
    </div>
  );
}

function Panel({ title, icon: Icon, children }: { title: string; icon: React.ComponentType<{ className?: string }>; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <h2 className="font-semibold flex items-center gap-2 mb-3"><Icon className="h-4 w-4 text-primary" />{title}</h2>
      {children}
    </div>
  );
}

function RankList({ items, labels }: { items: [string, number][]; labels: Record<string, string> }) {
  if (items.length === 0) return <p className="text-sm text-muted-foreground">Nothing yet.</p>;
  const max = Math.max(...items.map((i) => i[1]));
  return (
    <div className="space-y-2">
      {items.map(([id, count]) => (
        <div key={id}>
          <div className="flex items-center justify-between text-sm">
            <span>{labels[id] ?? "—"}</span>
            <span className="text-muted-foreground">{count}</span>
          </div>
          <div className="h-2 rounded-full bg-secondary mt-1 overflow-hidden">
            <div className="h-full bg-primary" style={{ width: `${(count / max) * 100}%` }} />
          </div>
        </div>
      ))}
    </div>
  );
}

function groupCount<T>(arr: T[], key: (t: T) => string): [string, number][] {
  const map = new Map<string, number>();
  for (const a of arr) map.set(key(a), (map.get(key(a)) ?? 0) + 1);
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}