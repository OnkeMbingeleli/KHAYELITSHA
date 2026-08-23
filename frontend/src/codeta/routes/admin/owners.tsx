import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CodetaSticker } from "@/components/CodetaSticker";
import { toast } from "sonner";
import { Check, X, Printer } from "lucide-react";

export const Route = createFileRoute("/admin/owners")({
  component: OwnersPage,
});

type Owner = {
  id: string; full_name: string; surname: string; id_number: string; contact: string; email: string;
  status: "pending" | "approved" | "suspended"; owner_code: string | null; created_at: string;
  branch_id: string;
};
type Vehicle = {
  id: string; owner_id: string; number_plate: string; make: string | null; model: string | null;
  seats: number; qr_token: string; primary_route_id: string | null; active: boolean;
};

function OwnersPage() {
  const [owners, setOwners] = useState<Owner[]>([]);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [routes, setRoutes] = useState<Record<string, string>>({});

  async function refresh() {
    const [{ data: o }, { data: v }, { data: r }] = await Promise.all([
      supabase.from("owners").select("*").order("created_at", { ascending: false }),
      supabase.from("vehicles").select("*"),
      supabase.from("routes").select("id,name"),
    ]);
    setOwners((o ?? []) as Owner[]);
    setVehicles((v ?? []) as Vehicle[]);
    setRoutes(Object.fromEntries((r ?? []).map((x) => [x.id, x.name])));
  }
  useEffect(() => { refresh(); }, []);

  async function setStatus(id: string, status: Owner["status"]) {
    const { error } = await supabase.from("owners").update({ status }).eq("id", id);
    if (error) return toast.error(error.message);
    toast.success(`Owner ${status}`);
    refresh();
  }

  const pending = owners.filter((o) => o.status === "pending");
  const approved = owners.filter((o) => o.status === "approved");

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Owners</h1>
      <Tabs defaultValue="pending">
        <TabsList>
          <TabsTrigger value="pending">Pending ({pending.length})</TabsTrigger>
          <TabsTrigger value="approved">Approved ({approved.length})</TabsTrigger>
        </TabsList>
        <TabsContent value="pending" className="space-y-3 mt-3">
          {pending.length === 0 && <p className="text-sm text-muted-foreground">No pending applications.</p>}
          {pending.map((o) => <OwnerCard key={o.id} owner={o} vehicles={vehicles.filter(v => v.owner_id === o.id)} routes={routes}
            actions={
              <>
                <Button size="sm" onClick={() => setStatus(o.id, "approved")}><Check className="h-4 w-4 mr-1" />Approve</Button>
                <Button size="sm" variant="ghost" onClick={() => setStatus(o.id, "suspended")}><X className="h-4 w-4 mr-1" />Reject</Button>
              </>
            } />)}
        </TabsContent>
        <TabsContent value="approved" className="space-y-3 mt-3">
          {approved.length === 0 && <p className="text-sm text-muted-foreground">No approved owners yet.</p>}
          {approved.map((o) => <OwnerCard key={o.id} owner={o} vehicles={vehicles.filter(v => v.owner_id === o.id)} routes={routes} />)}
        </TabsContent>
      </Tabs>
    </div>
  );
}

function OwnerCard({ owner, vehicles, routes, actions }: { owner: Owner; vehicles: Vehicle[]; routes: Record<string, string>; actions?: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="font-semibold">{owner.full_name} {owner.surname}</h3>
          <p className="text-xs text-muted-foreground">ID {owner.id_number} · {owner.contact} · {owner.email}</p>
          {owner.owner_code && <p className="text-xs mt-1 text-primary font-mono">{owner.owner_code}</p>}
        </div>
        <div className="flex gap-1">{actions}</div>
      </div>
      <div className="mt-3 grid sm:grid-cols-2 gap-2">
        {vehicles.map((v) => (
          <div key={v.id} className="flex items-center justify-between rounded-lg border border-border px-3 py-2">
            <div>
              <p className="font-mono font-semibold">{v.number_plate}</p>
              <p className="text-xs text-muted-foreground">
                {v.make ?? ""} {v.model ?? ""} · {v.seats} seats · {routes[v.primary_route_id ?? ""] ?? "no route"}
              </p>
            </div>
            {owner.status === "approved" && (
              <Dialog>
                <DialogTrigger asChild>
                  <Button size="sm" variant="secondary"><Printer className="h-4 w-4 mr-1" />Sticker</Button>
                </DialogTrigger>
                <DialogContent className="max-w-sm">
                  <DialogHeader><DialogTitle>QR Sticker — {v.number_plate}</DialogTitle></DialogHeader>
                  <div className="flex justify-center py-4">
                    <CodetaSticker
                      data={JSON.stringify({ p: v.number_plate, o: owner.owner_code, r: v.primary_route_id, s: v.seats, t: v.qr_token })}
                      ownerCode={owner.owner_code ?? ""}
                      plate={v.number_plate}
                      routeName={routes[v.primary_route_id ?? ""] ?? "—"}
                      seats={v.seats}
                    />
                  </div>
                  <Button onClick={() => window.print()} variant="secondary" className="w-full">Print</Button>
                </DialogContent>
              </Dialog>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}