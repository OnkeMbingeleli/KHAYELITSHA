import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { randomBytes, pbkdf2Sync } from "crypto";
import { supabaseAdmin } from "@/integrations/supabase/client.server";

const MAX_DEVICES = 2;
const IDLE_MS = 30 * 60 * 1000; // 30 min

function hashCode(code: string, salt: string) {
  return pbkdf2Sync(code, salt, 50000, 32, "sha256").toString("hex");
}

export const listOfficesPublic = createServerFn({ method: "GET" }).handler(async () => {
  const { data, error } = await supabaseAdmin
    .from("subhead_offices")
    .select("id, name, town, route_id, branch_id")
    .order("name");
  if (error) throw new Error(error.message);
  return { offices: data ?? [] };
});

export const subheadLogin = createServerFn({ method: "POST" })
  .inputValidator((d) =>
    z.object({
      office_id: z.string().uuid(),
      code: z.string().min(3).max(64),
      user_agent: z.string().max(500).optional(),
    }).parse(d)
  )
  .handler(async ({ data }) => {
    const { data: office, error } = await supabaseAdmin
      .from("subhead_offices")
      .select("id, access_code_hash, access_code_salt")
      .eq("id", data.office_id)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!office) return { ok: false as const, reason: "Office not found" };

    const provided = hashCode(data.code, office.access_code_salt);
    if (provided !== office.access_code_hash) {
      return { ok: false as const, reason: "Wrong access code" };
    }

    // Prune stale sessions
    await supabaseAdmin
      .from("subhead_sessions")
      .delete()
      .eq("office_id", office.id)
      .lt("last_seen_at", new Date(Date.now() - IDLE_MS).toISOString());

    const { count } = await supabaseAdmin
      .from("subhead_sessions")
      .select("id", { count: "exact", head: true })
      .eq("office_id", office.id);

    if ((count ?? 0) >= MAX_DEVICES) {
      return { ok: false as const, reason: `Maximum ${MAX_DEVICES} devices already signed in for this office.` };
    }

    const token = randomBytes(24).toString("hex");
    const { error: insErr } = await supabaseAdmin.from("subhead_sessions").insert({
      office_id: office.id,
      device_token: token,
      user_agent: data.user_agent ?? null,
    });
    if (insErr) throw new Error(insErr.message);

    return { ok: true as const, device_token: token, office_id: office.id };
  });

export const subheadHeartbeat = createServerFn({ method: "POST" })
  .inputValidator((d) => z.object({ device_token: z.string().min(10) }).parse(d))
  .handler(async ({ data }) => {
    const { data: row, error } = await supabaseAdmin
      .from("subhead_sessions")
      .update({ last_seen_at: new Date().toISOString() })
      .eq("device_token", data.device_token)
      .select("office_id")
      .maybeSingle();
    if (error) throw new Error(error.message);
    return { ok: !!row, office_id: row?.office_id ?? null };
  });

export const subheadLogout = createServerFn({ method: "POST" })
  .inputValidator((d) => z.object({ device_token: z.string().min(10) }).parse(d))
  .handler(async ({ data }) => {
    await supabaseAdmin.from("subhead_sessions").delete().eq("device_token", data.device_token);
    return { ok: true };
  });

export const getSubheadMapData = createServerFn({ method: "POST" })
  .inputValidator((d) => z.object({ device_token: z.string().min(10) }).parse(d))
  .handler(async ({ data }) => {
    // Validate session
    const { data: sess } = await supabaseAdmin
      .from("subhead_sessions")
      .select("office_id, last_seen_at")
      .eq("device_token", data.device_token)
      .maybeSingle();
    if (!sess) return { ok: false as const, reason: "Session expired" };
    if (new Date(sess.last_seen_at).getTime() < Date.now() - IDLE_MS) {
      return { ok: false as const, reason: "Session expired" };
    }

    const { data: me } = await supabaseAdmin
      .from("subhead_offices")
      .select("branch_id")
      .eq("id", sess.office_id)
      .single();
    const branchId = me!.branch_id;

    // All offices in same branch
    const { data: offices } = await supabaseAdmin
      .from("subhead_offices")
      .select("id, name, town, lat, lng, route_id, branch_id")
      .eq("branch_id", branchId);

    // Today's loads in this branch grouped by route
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    const { data: loads } = await supabaseAdmin
      .from("loads")
      .select("route_id, recorded_at, number_plate, overload")
      .eq("branch_id", branchId)
      .gte("recorded_at", since.toISOString())
      .order("recorded_at", { ascending: false });

    const byRoute = new Map<string, { count: number; lastAt: string; lastPlate: string; overloads: number }>();
    for (const l of loads ?? []) {
      const cur = byRoute.get(l.route_id) ?? { count: 0, lastAt: l.recorded_at, lastPlate: l.number_plate, overloads: 0 };
      cur.count += 1;
      if (l.overload) cur.overloads += 1;
      byRoute.set(l.route_id, cur);
    }

    return {
      ok: true as const,
      my_office_id: sess.office_id,
      offices: (offices ?? []).map((o) => {
        const stat = byRoute.get(o.route_id);
        return {
          ...o,
          today_count: stat?.count ?? 0,
          last_at: stat?.lastAt ?? null,
          last_plate: stat?.lastPlate ?? null,
          overloads: stat?.overloads ?? 0,
        };
      }),
    };
  });

// ===== Admin =====

export const adminListOffices = createServerFn({ method: "GET" }).handler(async () => {
  const [{ data: offices }, { data: sessions }, { data: routes }] = await Promise.all([
    supabaseAdmin.from("subhead_offices").select("*").order("name"),
    supabaseAdmin.from("subhead_sessions").select("id, office_id, user_agent, last_seen_at"),
    supabaseAdmin.from("routes").select("id, name, code, branch_id"),
  ]);
  return { offices: offices ?? [], sessions: sessions ?? [], routes: routes ?? [] };
});

export const adminCreateOffice = createServerFn({ method: "POST" })
  .inputValidator((d) =>
    z.object({
      route_id: z.string().uuid(),
      branch_id: z.string().uuid(),
      name: z.string().min(1).max(120),
      town: z.string().max(120).optional(),
      lat: z.number().min(-90).max(90),
      lng: z.number().min(-180).max(180),
      code: z.string().min(4).max(32),
    }).parse(d)
  )
  .handler(async ({ data }) => {
    const salt = randomBytes(16).toString("hex");
    const hash = hashCode(data.code, salt);
    const { error } = await supabaseAdmin.from("subhead_offices").insert({
      route_id: data.route_id,
      branch_id: data.branch_id,
      name: data.name,
      town: data.town ?? null,
      lat: data.lat,
      lng: data.lng,
      access_code_hash: hash,
      access_code_salt: salt,
    });
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const adminUpdateOffice = createServerFn({ method: "POST" })
  .inputValidator((d) =>
    z.object({
      id: z.string().uuid(),
      name: z.string().min(1).max(120).optional(),
      town: z.string().max(120).nullable().optional(),
      lat: z.number().min(-90).max(90).optional(),
      lng: z.number().min(-180).max(180).optional(),
      code: z.string().min(4).max(32).optional(),
    }).parse(d)
  )
  .handler(async ({ data }) => {
    const patch: Record<string, any> = { updated_at: new Date().toISOString() };
    if (data.name !== undefined) patch.name = data.name;
    if (data.town !== undefined) patch.town = data.town;
    if (data.lat !== undefined) patch.lat = data.lat;
    if (data.lng !== undefined) patch.lng = data.lng;
    if (data.code !== undefined) {
      const salt = randomBytes(16).toString("hex");
      patch.access_code_salt = salt;
      patch.access_code_hash = hashCode(data.code, salt);
    }
    const { error } = await supabaseAdmin.from("subhead_offices").update(patch as any).eq("id", data.id);
    if (error) throw new Error(error.message);
    if (data.code) {
      // force-logout all devices when code changes
      await supabaseAdmin.from("subhead_sessions").delete().eq("office_id", data.id);
    }
    return { ok: true };
  });

export const adminDeleteOffice = createServerFn({ method: "POST" })
  .inputValidator((d) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const { error } = await supabaseAdmin.from("subhead_offices").delete().eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const adminKickSession = createServerFn({ method: "POST" })
  .inputValidator((d) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    await supabaseAdmin.from("subhead_sessions").delete().eq("id", data.id);
    return { ok: true };
  });