import { createFileRoute } from "@tanstack/react-router";
import { Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth";
import { ClipboardList, Users, ShieldCheck, QrCode } from "lucide-react";

export const Route = createFileRoute("/")({
  component: Index,
});

function Index() {
  const { user, isStaff, roles } = useAuth();
  const isPatroller = roles.includes("patroller");
  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="flex items-center justify-between px-6 py-4 border-b border-border">
        <div className="flex items-center gap-2">
          <div className="h-9 w-9 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">L</div>
          <span className="text-xl font-bold tracking-wide">LAGUNYA</span>
        </div>
        <div className="flex items-center gap-2">
          {user ? (
            <>
              <Button asChild variant="secondary"><Link to="/marshal">Marshal</Link></Button>
              {isPatroller && <Button asChild variant="secondary"><Link to="/patroller">Patroller</Link></Button>}
              <Button asChild variant="outline"><Link to="/subhead">Mini route office</Link></Button>
              {isStaff && <Button asChild><Link to="/admin">Admin</Link></Button>}
            </>
          ) : (
            <Button asChild><Link to="/login">Sign in</Link></Button>
          )}
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-6 py-16">
        <h1 className="text-4xl md:text-6xl font-bold leading-tight">
          Fair, transparent <span className="text-primary">load logging</span> for taxi associations.
        </h1>
        <p className="mt-4 text-lg text-muted-foreground max-w-2xl">
          LAGUNYA replaces shouting matches at the rank with a simple system: marshals log every load,
          owners see real numbers, and management gets live dashboards. Built for the Kuwait branch first.
        </p>
        <div className="mt-8 flex flex-wrap gap-3">
          <Button asChild size="lg"><Link to="/register-owner">Register as an owner</Link></Button>
          <Button asChild size="lg" variant="secondary"><Link to="/login">Marshal sign in</Link></Button>
          <Button asChild size="lg" variant="outline"><Link to="/subhead">Subhead office</Link></Button>
        </div>

        <section className="mt-20 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {[
            { icon: ClipboardList, t: "Log loads instantly", d: "Marshals just type the number plate. Date, time and rank are captured automatically." },
            { icon: Users, t: "Owner registry", d: "Owners register online and get a printable ID card and QR sticker per vehicle." },
            { icon: QrCode, t: "QR stickers", d: "Round LAGUNYA stickers identify each vehicle by route, plate, owner and seats." },
            { icon: ShieldCheck, t: "Daily fairness cap", d: "Once a taxi hits the daily cap, the system blocks more loads. Equal turn for everyone." },
          ].map(({ icon: Icon, t, d }) => (
            <div key={t} className="p-5 rounded-xl bg-card border border-border">
              <Icon className="h-6 w-6 text-primary" />
              <h3 className="mt-3 font-semibold">{t}</h3>
              <p className="mt-1 text-sm text-muted-foreground">{d}</p>
            </div>
          ))}
        </section>
      </main>
      <footer className="px-6 py-8 text-center text-sm text-muted-foreground border-t border-border">
        © LAGUNYA — Kuwait branch pilot
      </footer>
    </div>
  );
}
