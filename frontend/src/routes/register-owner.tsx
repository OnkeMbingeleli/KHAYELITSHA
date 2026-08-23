import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState, type FormEvent } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { Plus, Trash2, CheckCircle2 } from "lucide-react";

export const Route = createFileRoute("/register-owner")({
  head: () => ({
    meta: [
      { title: "Owner registration — CODETA" },
      { name: "description", content: "Register as a taxi owner with the Kuwait branch." },
    ],
  }),
  component: RegisterOwnerPage,
});

type VehicleInput = { number_plate: string; make: string; model: string; seats: number; primary_route_id: string };

function RegisterOwnerPage() {
  const [branches, setBranches] = useState<{ id: string; name: string }[]>([]);
  const [routes, setRoutes] = useState<{ id: string; name: string }[]>([]);
  const [branchId, setBranchId] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [busy, setBusy] = useState(false);

  const [fullName, setFullName] = useState("");
  const [surname, setSurname] = useState("");
  const [dob, setDob] = useState("");
  const [idNumber, setIdNumber] = useState("");
  const [contact, setContact] = useState("");
  const [email, setEmail] = useState("");
  const [vehicles, setVehicles] = useState<VehicleInput[]>([
    { number_plate: "", make: "", model: "", seats: 15, primary_route_id: "" },
  ]);

  useEffect(() => {
    (async () => {
      const [{ data: b }, { data: r }] = await Promise.all([
        supabase.from("branches").select("id,name").order("name"),
        supabase.from("routes").select("id,name").order("name"),
      ]);
      setBranches(b ?? []);
      setRoutes(r ?? []);
      if (b?.length) setBranchId(b[0].id);
    })();
  }, []);

  function setVeh(i: number, patch: Partial<VehicleInput>) {
    setVehicles((vs) => vs.map((v, idx) => (idx === i ? { ...v, ...patch } : v)));
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!branchId) return toast.error("Pick a branch");
    if (vehicles.some((v) => !v.number_plate.trim())) return toast.error("Every vehicle needs a number plate");
    setBusy(true);
    const { data: owner, error } = await supabase
      .from("owners")
      .insert({
        branch_id: branchId,
        full_name: fullName.trim(),
        surname: surname.trim(),
        date_of_birth: dob || null,
        id_number: idNumber.trim(),
        contact: contact.trim(),
        email: email.trim(),
      })
      .select("id")
      .single();
    if (error || !owner) { setBusy(false); return toast.error(error?.message ?? "Failed"); }

    const rows = vehicles.map((v) => ({
      owner_id: owner.id,
      branch_id: branchId,
      number_plate: v.number_plate.trim().toUpperCase(),
      make: v.make.trim() || null,
      model: v.model.trim() || null,
      seats: v.seats || 15,
      primary_route_id: v.primary_route_id || null,
    }));
    const { error: vErr } = await supabase.from("vehicles").insert(rows);
    setBusy(false);
    if (vErr) return toast.error(vErr.message);
    setSubmitted(true);
    toast.success("Application submitted");
  }

  if (submitted) {
    return (
      <div className="min-h-screen grid place-items-center bg-background text-foreground p-6">
        <div className="max-w-md text-center space-y-4 rounded-2xl border border-border bg-card p-8">
          <CheckCircle2 className="h-12 w-12 text-accent mx-auto" />
          <h1 className="text-2xl font-bold">Application received</h1>
          <p className="text-muted-foreground">
            Your registration is pending approval. Once approved, you'll receive your owner ID code and printable QR stickers for each vehicle.
          </p>
          <Button asChild><Link to="/">Back home</Link></Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="px-6 py-4 border-b border-border flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground grid place-items-center font-bold">C</div>
          <span className="font-semibold">CODETA</span>
        </Link>
      </header>
      <main className="max-w-2xl mx-auto px-6 py-10">
        <h1 className="text-3xl font-bold">Owner registration</h1>
        <p className="text-muted-foreground mt-1">Register yourself and the vehicles you operate. The association will approve and issue your QR stickers.</p>

        <form onSubmit={submit} className="mt-8 space-y-6">
          <section className="rounded-xl border border-border bg-card p-5 space-y-3">
            <h2 className="font-semibold">Your details</h2>
            <div className="grid md:grid-cols-2 gap-3">
              <div><Label>First name</Label><Input required value={fullName} onChange={(e) => setFullName(e.target.value)} /></div>
              <div><Label>Surname</Label><Input required value={surname} onChange={(e) => setSurname(e.target.value)} /></div>
              <div><Label>Date of birth</Label><Input type="date" value={dob} onChange={(e) => setDob(e.target.value)} /></div>
              <div><Label>ID number</Label><Input required value={idNumber} onChange={(e) => setIdNumber(e.target.value)} /></div>
              <div><Label>Contact</Label><Input required value={contact} onChange={(e) => setContact(e.target.value)} /></div>
              <div><Label>Email</Label><Input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
              <div className="md:col-span-2">
                <Label>Branch</Label>
                <Select value={branchId} onValueChange={setBranchId}>
                  <SelectTrigger><SelectValue placeholder="Pick branch" /></SelectTrigger>
                  <SelectContent>{branches.map((b) => <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>)}</SelectContent>
                </Select>
              </div>
            </div>
          </section>

          <section className="rounded-xl border border-border bg-card p-5 space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">Vehicles</h2>
              <Button type="button" size="sm" variant="secondary" onClick={() => setVehicles((v) => [...v, { number_plate: "", make: "", model: "", seats: 15, primary_route_id: "" }])}>
                <Plus className="h-4 w-4 mr-1" />Add vehicle
              </Button>
            </div>
            {vehicles.map((v, i) => (
              <div key={i} className="rounded-lg border border-border p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Vehicle {i + 1}</span>
                  {vehicles.length > 1 && (
                    <Button type="button" size="sm" variant="ghost" onClick={() => setVehicles((vs) => vs.filter((_, idx) => idx !== i))}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
                <div className="grid md:grid-cols-2 gap-2">
                  <div><Label>Number plate</Label><Input required value={v.number_plate} onChange={(e) => setVeh(i, { number_plate: e.target.value.toUpperCase() })} /></div>
                  <div><Label>Seats</Label><Input type="number" min={4} max={30} value={v.seats} onChange={(e) => setVeh(i, { seats: Number(e.target.value) })} /></div>
                  <div><Label>Make</Label><Input value={v.make} onChange={(e) => setVeh(i, { make: e.target.value })} placeholder="Toyota" /></div>
                  <div><Label>Model</Label><Input value={v.model} onChange={(e) => setVeh(i, { model: e.target.value })} placeholder="Quantum" /></div>
                  <div className="md:col-span-2">
                    <Label>Primary route</Label>
                    <Select value={v.primary_route_id} onValueChange={(val) => setVeh(i, { primary_route_id: val })}>
                      <SelectTrigger><SelectValue placeholder="Pick route" /></SelectTrigger>
                      <SelectContent>{routes.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
                    </Select>
                  </div>
                </div>
              </div>
            ))}
          </section>

          <Button disabled={busy} className="w-full">{busy ? "Submitting…" : "Submit application"}</Button>
        </form>
      </main>
    </div>
  );
}