import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { toast } from "sonner";

export const Route = createFileRoute("/login")({
  head: () => ({ meta: [{ title: "Sign in — CODETA" }] }),
  component: LoginPage,
});

function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [surname, setSurname] = useState("");
  const [busy, setBusy] = useState(false);

  async function signIn(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Signed in");
    navigate({ to: "/marshal" });
  }

  async function signUp(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/`,
        data: { full_name: fullName, surname },
      },
    });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Account created — you are signed in.");
    navigate({ to: "/marshal" });
  }

  return (
    <div className="min-h-screen grid place-items-center bg-background text-foreground p-4">
      <div className="w-full max-w-md">
        <Link to="/" className="flex items-center gap-2 mb-6 justify-center">
          <div className="h-9 w-9 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">C</div>
          <span className="text-xl font-bold tracking-wide">CODETA</span>
        </Link>
        <div className="rounded-2xl border border-border bg-card p-6">
          <Tabs defaultValue="signin">
            <TabsList className="w-full">
              <TabsTrigger value="signin" className="flex-1">Sign in</TabsTrigger>
              <TabsTrigger value="signup" className="flex-1">Create account</TabsTrigger>
            </TabsList>
            <TabsContent value="signin">
              <form className="space-y-3 mt-4" onSubmit={signIn}>
                <div><Label>Email</Label><Input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                <div><Label>Password</Label><Input type="password" required value={password} onChange={(e) => setPassword(e.target.value)} /></div>
                <Button className="w-full" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</Button>
              </form>
            </TabsContent>
            <TabsContent value="signup">
              <form className="space-y-3 mt-4" onSubmit={signUp}>
                <div className="grid grid-cols-2 gap-2">
                  <div><Label>Name</Label><Input required value={fullName} onChange={(e) => setFullName(e.target.value)} /></div>
                  <div><Label>Surname</Label><Input required value={surname} onChange={(e) => setSurname(e.target.value)} /></div>
                </div>
                <div><Label>Email</Label><Input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                <div><Label>Password</Label><Input type="password" required minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} /></div>
                <Button className="w-full" disabled={busy}>{busy ? "Creating…" : "Create account"}</Button>
                <p className="text-xs text-muted-foreground text-center">New accounts default to the Marshal role. An admin can promote you.</p>
              </form>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}