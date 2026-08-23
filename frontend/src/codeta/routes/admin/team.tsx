import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { useAuth } from "@/lib/auth";

export const Route = createFileRoute("/admin/team")({
  component: TeamPage,
});

type AppRole = "super_admin" | "management" | "marshal" | "patroller";
const ROLES: AppRole[] = ["super_admin", "management", "marshal", "patroller"];

type Profile = { id: string; full_name: string | null; surname: string | null; email: string | null };
type RoleRow = { user_id: string; role: AppRole };
type Assignment = { id: string; user_id: string; route_id: string; rank_id: string | null };

function TeamPage() {
  const { user, isAdmin } = useAuth();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [roles, setRoles] = useState<RoleRow[]>([]);
  const [routes, setRoutes] = useState<{ id: string; name: string }[]>([]);
  const [ranks, setRanks] = useState<{ id: string; name: string; branch_id: string }[]>([]);
  const [branches, setBranches] = useState<{ id: string; name: string }[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);

  async function refresh() {
    const [{ data: p }, { data: r }, { data: rt }, { data: rk }, { data: b }, { data: a }] = await Promise.all([
      supabase.from("profiles").select("id,full_name,surname,email"),
      supabase.from("user_roles").select("user_id,role"),
      supabase.from("routes").select("id,name").order("name"),
      supabase.from("ranks").select("id,name,branch_id").order("code"),
      supabase.from("branches").select("id,name"),
      supabase.from("marshal_assignments").select("id,user_id,route_id,rank_id"),
    ]);
    setProfiles((p ?? []) as Profile[]);
    setRoles((r ?? []) as RoleRow[]);
    setRoutes(rt ?? []);
    setRanks(rk ?? []);
    setBranches(b ?? []);
    setAssignments((a ?? []) as Assignment[]);
  }
  useEffect(() => { refresh(); }, []);

  async function setRole(userId: string, role: AppRole, has: boolean) {
    if (has) {
      const { error } = await supabase.from("user_roles").delete().eq("user_id", userId).eq("role", role);
      if (error) return toast.error(error.message);
    } else {
      const { error } = await supabase.from("user_roles").insert({ user_id: userId, role });
      if (error) return toast.error(error.message);
    }
    refresh();
  }

  async function assignMarshal(userId: string, routeId: string, rankId: string | null) {
    const branch_id = (rankId ? ranks.find(r => r.id === rankId)?.branch_id : branches[0]?.id) ?? branches[0]?.id;
    if (!branch_id) return toast.error("No branch");
    const { error } = await supabase.from("marshal_assignments").insert({
      user_id: userId, route_id: routeId, rank_id: rankId, branch_id,
    });
    if (error) return toast.error(error.message);
    toast.success("Assignment added");
    refresh();
  }

  if (!isAdmin) {
    return <p className="text-sm text-muted-foreground">You need super-admin access to manage roles. Ask the system owner.</p>;
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Team & roles</h1>
        <p className="text-sm text-muted-foreground">Promote users, and assign marshals to routes/ranks. Your user id: <span className="font-mono">{user?.id}</span></p>
      </div>

      <div className="rounded-xl border border-border bg-card p-4">
        <p className="text-xs text-muted-foreground mb-3">
          The first super-admin must be set manually in the database. Use this user-id above.
        </p>
        <table className="w-full text-sm">
          <thead><tr className="text-left text-muted-foreground"><th className="py-2">User</th><th>Roles</th><th>Marshal assignments</th></tr></thead>
          <tbody>
            {profiles.map((p) => {
              const userRoles = roles.filter((r) => r.user_id === p.id).map((r) => r.role);
              const myAssignments = assignments.filter((a) => a.user_id === p.id);
              return (
                <tr key={p.id} className="border-t border-border align-top">
                  <td className="py-2 pr-2">
                    <p className="font-medium">{p.full_name} {p.surname}</p>
                    <p className="text-xs text-muted-foreground">{p.email}</p>
                  </td>
                  <td className="py-2 pr-2">
                    <div className="flex flex-wrap gap-1">
                      {ROLES.map((role) => {
                        const has = userRoles.includes(role);
                        return (
                          <button key={role} onClick={() => setRole(p.id, role, has)}
                            className={`text-xs px-2 py-1 rounded-md border ${has ? "bg-primary text-primary-foreground border-primary" : "border-border hover:bg-secondary"}`}>
                            {role}
                          </button>
                        );
                      })}
                    </div>
                  </td>
                  <td className="py-2">
                    <div className="space-y-1">
                      {myAssignments.map((a) => (
                        <div key={a.id} className="text-xs flex items-center gap-2">
                          <span>{routes.find(r => r.id === a.route_id)?.name ?? "—"}</span>
                          <span className="text-muted-foreground">@ {ranks.find(r => r.id === a.rank_id)?.name ?? "any"}</span>
                          <Button size="sm" variant="ghost" className="h-5 px-1 text-xs"
                            onClick={async () => { await supabase.from("marshal_assignments").delete().eq("id", a.id); refresh(); }}>×</Button>
                        </div>
                      ))}
                      <AssignForm onAdd={(routeId, rankId) => assignMarshal(p.id, routeId, rankId)} routes={routes} ranks={ranks} />
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function AssignForm({ routes, ranks, onAdd }: { routes: { id: string; name: string }[]; ranks: { id: string; name: string }[]; onAdd: (routeId: string, rankId: string | null) => void }) {
  const [routeId, setRouteId] = useState("");
  const [rankId, setRankId] = useState<string>("");
  return (
    <div className="flex items-center gap-1">
      <Select value={routeId} onValueChange={setRouteId}>
        <SelectTrigger className="h-7 text-xs w-32"><SelectValue placeholder="Route" /></SelectTrigger>
        <SelectContent>{routes.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
      </Select>
      <Select value={rankId} onValueChange={setRankId}>
        <SelectTrigger className="h-7 text-xs w-28"><SelectValue placeholder="Rank" /></SelectTrigger>
        <SelectContent>{ranks.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
      </Select>
      <Button size="sm" variant="secondary" className="h-7 text-xs" disabled={!routeId}
        onClick={() => { onAdd(routeId, rankId || null); setRouteId(""); setRankId(""); }}>+</Button>
    </div>
  );
}