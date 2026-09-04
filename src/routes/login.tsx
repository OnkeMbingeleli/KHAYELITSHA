import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { toast } from "sonner";

/** Where to land a signed-in user depending on their roles. */
function pickLandingRoute(roles: string[]): "/admin" | "/marshal" | "/patroller" {
  if (roles.includes("super_admin") || roles.includes("management")) return "/admin";
  if (roles.includes("marshal")) return "/marshal";
  if (roles.includes("patroller")) return "/patroller";
  return "/marshal";
}

const codeTaWatermark = `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(`
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 900">
    <rect width="900" height="900" rx="36" fill="#0a5d8d"/>
    <circle cx="450" cy="450" r="300" fill="#ffffff" opacity="0.06"/>
    <g transform="translate(80 70)">
      <path d="M120 420C208 330 272 235 318 170C345 132 393 94 438 108C486 124 520 186 548 237C590 316 621 378 704 432C654 476 598 495 538 499C488 502 468 462 450 425C431 387 394 340 332 340C285 340 229 367 181 420C165 437 142 451 120 420Z" fill="#ffffff" opacity="0.92"/>
      <path d="M355 260C396 202 447 148 510 133C474 190 458 236 456 275C445 264 431 258 414 259C387 261 368 272 355 260Z" fill="#0a5d8d" opacity="0.18"/>
      <path d="M188 487C240 454 269 440 321 430C294 480 275 525 254 561C231 563 210 552 188 487Z" fill="#ffffff" opacity="0.9"/>
      <circle cx="150" cy="517" r="18" fill="#ffffff" opacity="0.95"/>
      <circle cx="750" cy="517" r="18" fill="#ffffff" opacity="0.95"/>
      <path d="M456 391C476 415 505 447 547 471C515 483 490 501 473 532C455 504 428 479 393 471C414 445 434 421 456 391Z" fill="#ffffff" opacity="0.9"/>
      <path d="M360 527C454 498 525 510 625 566" stroke="#ffffff" stroke-width="18" stroke-linecap="round" fill="none" opacity="0.9"/>
      <path d="M394 535C472 503 536 502 633 545" stroke="#0a5d8d" stroke-width="7" stroke-linecap="round" fill="none" opacity="0.5"/>
    </g>
    <text x="450" y="710" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="108" font-weight="800" letter-spacing="8">LAGUNYA</text>
    <text x="450" y="780" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="34" font-weight="700" letter-spacing="4">CATCH THE DOVE FOR PEACE</text>
  </svg>
`)}`;

export const Route = createFileRoute("/login")({
  head: () => ({ meta: [{ title: "Sign in — LAGUNYA" }] }),
  component: LoginPage,
});

function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [title, setTitle] = useState("Mr");
  const [fullName, setFullName] = useState("");
  const [surname, setSurname] = useState("");
  const [busy, setBusy] = useState(false);

  async function signIn(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) { setBusy(false); return toast.error(error.message); }

    let roles: string[] = [];
    if (data.user) {
      const { data: roleRows } = await supabase.from("user_roles").select("role").eq("user_id", data.user.id);
      roles = (roleRows ?? []).map((r) => r.role as string);
    }
    setBusy(false);

    const name = data.user?.user_metadata?.title
      ? `${data.user.user_metadata.title} ${data.user.user_metadata.surname ?? ""}`.trim()
      : (data.user?.user_metadata?.full_name ?? "");
    toast.success(name ? `Welcome, ${name}` : "Signed in");
    navigate({ to: pickLandingRoute(roles) });
  }

  async function signUp(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/`,
        data: { full_name: fullName, surname, title },
      },
    });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Account created — you are signed in.");
    navigate({ to: "/marshal" });
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-slate-950 text-foreground">
      <div
        className="absolute inset-0 bg-cover bg-center opacity-15"
        style={{
          backgroundImage: `url("${codeTaWatermark}")`,
          filter: "saturate(0.9) contrast(1.05)",
        }}
      />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(15,23,42,0.18),rgba(2,6,23,0.82))]" />

      <div className="relative z-10 grid min-h-screen place-items-center p-4">
        <div className="w-full max-w-md">
          <Link to="/" className="mb-6 flex items-center justify-center gap-2">
            <div className="grid h-9 w-9 place-items-center rounded-full bg-primary font-bold text-primary-foreground">L</div>
            <span className="text-xl font-bold tracking-wide text-white">LAGUNYA</span>
          </Link>
          <div className="rounded-2xl border border-white/10 bg-card/85 p-6 shadow-2xl backdrop-blur-sm">
            <Tabs defaultValue="signin">
              <TabsList className="w-full">
                <TabsTrigger value="signin" className="flex-1">Sign in</TabsTrigger>
                <TabsTrigger value="signup" className="flex-1">Create account</TabsTrigger>
              </TabsList>
              <TabsContent value="signin">
                <form className="mt-4 space-y-3" onSubmit={signIn}>
                  <div><Label>Email</Label><Input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                  <div><Label>Password</Label><Input type="password" required value={password} onChange={(e) => setPassword(e.target.value)} /></div>
                  <Button className="w-full" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</Button>
                </form>
              </TabsContent>
              <TabsContent value="signup">
                <form className="mt-4 space-y-3" onSubmit={signUp}>
                  <div className="grid grid-cols-3 gap-2">
                    <div>
                      <Label>Title</Label>
                      <Select value={title} onValueChange={setTitle}>
                        <SelectTrigger><SelectValue placeholder="Title" /></SelectTrigger>
                        <SelectContent>
                          <SelectItem value="Mr">Mr</SelectItem>
                          <SelectItem value="Mrs">Mrs</SelectItem>
                          <SelectItem value="Ms">Ms</SelectItem>
                          <SelectItem value="Miss">Miss</SelectItem>
                          <SelectItem value="Dr">Dr</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="col-span-2"><Label>Name</Label><Input required value={fullName} onChange={(e) => setFullName(e.target.value)} /></div>
                  </div>
                  <div><Label>Surname</Label><Input required value={surname} onChange={(e) => setSurname(e.target.value)} /></div>
                  <div><Label>Email</Label><Input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                  <div><Label>Password</Label><Input type="password" required minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} /></div>
                  <Button className="w-full" disabled={busy}>{busy ? "Creating…" : "Create account"}</Button>
                  <p className="text-center text-xs text-muted-foreground">New accounts default to the Marshal role. An admin can promote you.</p>
                </form>
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </div>
  );
}