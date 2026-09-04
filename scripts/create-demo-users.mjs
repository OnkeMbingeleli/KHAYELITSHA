import { createClient } from "@supabase/supabase-js";
import { existsSync, readFileSync } from "node:fs";

function readEnvFile() {
  if (!existsSync(".env")) return {};
  return Object.fromEntries(
    readFileSync(".env", "utf8")
      .split(/\r?\n/)
      .filter((line) => line.trim() && !line.trim().startsWith("#"))
      .map((line) => {
        const separator = line.indexOf("=");
        if (separator < 0) return [line.trim(), ""];
        return [line.slice(0, separator).trim(), line.slice(separator + 1).trim().replace(/^['\"]|['\"]$/g, "")];
      }),
  );
}

const envFile = readEnvFile();
const url = process.env.SUPABASE_URL || envFile.SUPABASE_URL || envFile.VITE_SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SECRET_KEY;

if (!url || !serviceKey || serviceKey === "PASTE_YOUR_SECRET_KEY_HERE_FROM_SUPABASE_DASHBOARD") {
  throw new Error("Set the real SUPABASE_SECRET_KEY first. In Git Bash use: export SUPABASE_SECRET_KEY='sb_secret_...'");
}

const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
const users = [
  { email: "admin@lagunya.local", password: "LagunyaAdmin2026!", name: "LAGUNYA Head Office", role: "super_admin" },
  { email: "marshal@lagunya.local", password: "LagunyaMarshal2026!", name: "LAGUNYA Marshal", role: "marshal" },
  { email: "patroller@lagunya.local", password: "LagunyaPatroller2026!", name: "LAGUNYA Patroller", role: "patroller" },
];

for (const user of users) {
  const { data, error } = await admin.auth.admin.createUser({
    email: user.email,
    password: user.password,
    email_confirm: true,
    user_metadata: { full_name: user.name },
  });

  if (error && !error.message.toLowerCase().includes("already been registered")) throw error;

  let userId = data.user?.id;
  if (!userId) {
    const page = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    userId = page.data.users.find((candidate) => candidate.email === user.email)?.id;
  }
  if (!userId) throw new Error(`Could not find ${user.email} after creating it.`);

  const { error: roleError } = await admin
    .from("user_roles")
    .upsert({ user_id: userId, role: user.role }, { onConflict: "user_id,role" });
  if (roleError) throw roleError;

  console.log(`${user.role}: ${user.email} / ${user.password}`);
}
