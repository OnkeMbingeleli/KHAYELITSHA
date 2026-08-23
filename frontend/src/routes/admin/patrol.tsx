import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { ShieldAlert, AlertTriangle, ClipboardCheck, Eye, CheckCircle2 } from "lucide-react";

export const Route = createFileRoute("/admin/patrol")({
  component: PatrolPage,
});

type Report = {
  id: string; patroller_id: string; report_type: string; severity: string;
  status: string; number_plate: string | null; description: string;
  recorded_at: string; rank_id: string | null; route_id: string | null;
  pass_fail: boolean | null; resolution_note: string | null;
};
type Profile = { id: string; full_name: string | null; surname: string | null };

const ICONS: Record<string, typeof AlertTriangle> = {
  overload: ShieldAlert, misconduct: AlertTriangle,
  roadworthy: ClipboardCheck, marshal_oversight: Eye,
};

function PatrolPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [ranks, setRanks] = useState<{id:string;name:string}[]>([]);
  const [routes, setRoutes] = useState<{id:string;name:string}[]>([]);
  const [filter, setFilter] = useState<string>("open");

  async function refresh() {
    const [{ data: r }, { data: p }, { data: rk }, { data: rt }] = await Promise.all([
      supabase.from("patrol_reports").select("*").order("recorded_at",{ascending:false}).limit(200),
      supabase.from("profiles").select("id,full_name,surname"),
      supabase.from("ranks").select("id,name"),
      supabase.from("routes").select("id,name"),
    ]);
    setReports((r ?? []) as Report[]);
    setProfiles((p ?? []) as Profile[]);
    setRanks(rk ?? []);
    setRoutes(rt ?? []);
  }
  useEffect(() => {
    refresh();
    const ch = supabase.channel("patrol_reports_admin")
      .on("postgres_changes", { event: "*", schema: "public", table: "patrol_reports" }, refresh)
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, []);

  async function setStatus(id: string, status: "reviewed" | "resolved") {
    const { data: u } = await supabase.auth.getUser();
    const { error } = await supabase.from("patrol_reports").update({
      status, reviewed_at: new Date().toISOString(), reviewed_by: u.user?.id,
    }).eq("id", id);
    if (error) return toast.error(error.message);
    toast.success(`Marked ${status}`);
  }

  const filtered = filter === "all" ? reports : reports.filter(r => r.status === filter);
  const counts = {
    open: reports.filter(r => r.status === "open").length,
    reviewed: reports.filter(r => r.status === "reviewed").length,
    resolved: reports.filter(r => r.status === "resolved").length,
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Patrol reports</h1>
          <p className="text-sm text-muted-foreground">Live feed from patrollers in the field.</p>
        </div>
        <Select value={filter} onValueChange={setFilter}>
          <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="open">Open ({counts.open})</SelectItem>
            <SelectItem value="reviewed">Reviewed ({counts.reviewed})</SelectItem>
            <SelectItem value="resolved">Resolved ({counts.resolved})</SelectItem>
            <SelectItem value="all">All</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {([["Open",counts.open,"text-destructive"],["Reviewed",counts.reviewed,"text-primary"],["Resolved",counts.resolved,"text-muted-foreground"]] as const).map(([l,n,c]) => (
          <div key={l} className="rounded-xl border border-border bg-card p-3">
            <p className="text-xs text-muted-foreground">{l}</p>
            <p className={`text-2xl font-bold ${c}`}>{n}</p>
          </div>
        ))}
      </div>

      <div className="space-y-2">
        {filtered.length === 0 && <p className="text-sm text-muted-foreground">No reports here.</p>}
        {filtered.map(r => {
          const Icon = ICONS[r.report_type] ?? AlertTriangle;
          const who = profiles.find(p => p.id === r.patroller_id);
          const rank = ranks.find(x => x.id === r.rank_id)?.name;
          const route = routes.find(x => x.id === r.route_id)?.name;
          return (
            <div key={r.id} className="rounded-xl border border-border bg-card p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3 flex-1 min-w-0">
                  <Icon className={`h-5 w-5 mt-0.5 ${r.severity==="high" ? "text-destructive" : "text-primary"}`} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-medium capitalize">{r.report_type.replace("_"," ")}</span>
                      <span className={`text-[10px] px-1.5 py-0.5 rounded-full uppercase ${r.severity==="high" ? "bg-destructive/20 text-destructive" : r.severity==="medium" ? "bg-primary/20 text-primary" : "bg-secondary text-secondary-foreground"}`}>{r.severity}</span>
                      {r.pass_fail !== null && (
                        <span className={`text-[10px] px-1.5 py-0.5 rounded-full uppercase ${r.pass_fail ? "bg-primary/20 text-primary" : "bg-destructive/20 text-destructive"}`}>
                          {r.pass_fail ? "pass" : "fail"}
                        </span>
                      )}
                      {r.number_plate && <span className="text-xs font-mono">{r.number_plate}</span>}
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {who ? `${who.full_name ?? ""} ${who.surname ?? ""}`.trim() : "Patroller"}
                      {rank && ` · ${rank}`}{route && ` · ${route}`}
                      {" · "}{new Date(r.recorded_at).toLocaleString()}
                    </p>
                    <p className="text-sm mt-2">{r.description}</p>
                  </div>
                </div>
                <div className="flex flex-col gap-1 shrink-0">
                  {r.status === "open" && (
                    <Button size="sm" variant="secondary" onClick={() => setStatus(r.id, "reviewed")}>Review</Button>
                  )}
                  {r.status !== "resolved" && (
                    <Button size="sm" onClick={() => setStatus(r.id, "resolved")}>
                      <CheckCircle2 className="h-3 w-3 mr-1" />Resolve
                    </Button>
                  )}
                  {r.status === "resolved" && <span className="text-xs text-muted-foreground">Done</span>}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
