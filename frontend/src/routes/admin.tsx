import { createFileRoute, Link, Outlet, useRouterState, useNavigate } from "@tanstack/react-router";
import { useEffect } from "react";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { LayoutDashboard, Users, UserCog, LogOut, ShieldAlert, MapPin } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/admin")({
  head: () => ({ meta: [{ title: "Admin — CODETA" }] }),
  component: AdminLayout,
});

function AdminLayout() {
  const { user, isStaff, loading } = useAuth();
  const navigate = useNavigate();
  const path = useRouterState({ select: (r) => r.location.pathname });

  useEffect(() => {
    if (loading) return;
    if (!user) navigate({ to: "/login" });
    else if (!isStaff) navigate({ to: "/" });
  }, [user, isStaff, loading, navigate]);

  const nav = [
    { to: "/admin", label: "Dashboard", icon: LayoutDashboard },
    { to: "/admin/owners", label: "Owners", icon: Users },
    { to: "/admin/patrol", label: "Patrol reports", icon: ShieldAlert },
    { to: "/admin/subheads", label: "Subhead offices", icon: MapPin },
    { to: "/admin/team", label: "Team & roles", icon: UserCog },
  ];

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="px-4 py-3 border-b border-border flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">C</div>
          <span className="font-semibold">CODETA · Admin</span>
        </Link>
        <Button size="sm" variant="ghost" onClick={async () => { await supabase.auth.signOut(); navigate({ to: "/" }); }}>
          <LogOut className="h-4 w-4" />
        </Button>
      </header>
      <div className="max-w-6xl mx-auto px-4 py-6 grid md:grid-cols-[200px_1fr] gap-6">
        <nav className="space-y-1">
          {nav.map((n) => {
            const active = path === n.to;
            return (
              <Link key={n.to} to={n.to}
                className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm ${active ? "bg-primary text-primary-foreground" : "hover:bg-secondary text-foreground"}`}>
                <n.icon className="h-4 w-4" />{n.label}
              </Link>
            );
          })}
        </nav>
        <main><Outlet /></main>
      </div>
    </div>
  );
}