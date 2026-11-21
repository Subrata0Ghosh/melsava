import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing server environment variables." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Authenticate calling user using the Bearer JWT token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    if (!token) {
      return new Response(
        JSON.stringify({ error: "Empty or invalid Authorization Bearer token." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired user session." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;

    // 2. Verify recent reauthentication server-side (do not trust client timestamps)
    // Inspect token auth_time or iat claims (max 15 minutes = 900s)
    let authTime = 0;
    try {
      const parts = token.split(".");
      if (parts.length === 3) {
        // Base64URL decode
        const b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
        const payloadJson = atob(b64);
        const claims = JSON.parse(payloadJson);
        authTime = claims.auth_time || claims.iat || 0;
      }
    } catch (_) {
      authTime = 0;
    }

    if (authTime === 0 && user.last_sign_in_at) {
      authTime = Math.floor(new Date(user.last_sign_in_at).getTime() / 1000);
    }

    const nowSec = Math.floor(Date.now() / 1000);
    const maxAuthAgeSec = 15 * 60; // 15 minutes
    if (authTime > 0 && nowSec - authTime > maxAuthAgeSec) {
      return new Response(
        JSON.stringify({
          error: "Recent reauthentication required. For your security, please sign in again before permanently deleting your account.",
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Verify explicit typed confirmation phrase "DELETE"
    let body: any = {};
    try {
      body = await req.json();
    } catch (_) {
      body = {};
    }

    const confirmation = (body?.confirmation ?? "").toString().trim();
    if (confirmation !== "DELETE") {
      return new Response(
        JSON.stringify({
          error: "Explicit confirmation phrase 'DELETE' is required to permanently delete your account.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Admin client with service_role key to delete storage & auth user
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // 5. Clean up user-owned avatar files safely in Supabase Storage
    try {
      const { data: avatarFiles, error: listErr } = await adminClient.storage
        .from("avatars")
        .list(userId);

      if (avatarFiles && avatarFiles.length > 0) {
        const filePaths = avatarFiles.map((f) => `${userId}/${f.name}`);
        const { error: removeErr } = await adminClient.storage.from("avatars").remove(filePaths);
        if (removeErr) {
          console.warn(`Storage avatar deletion notice for ${userId}:`, removeErr);
        }
      }
    } catch (storageErr) {
      console.warn(`Storage avatar cleanup error for ${userId}:`, storageErr);
    }

    // 6. Delete from Supabase Auth permanently via admin client
    // Note: Deleting from auth.users cascades through PostgreSQL foreign keys to:
    // public.profiles -> profile_private, profile_interests, profile_intentions,
    // connections, conversations, messages, app_notifications, blocks, reports.
    // Crucially: we do NOT delete public.profiles BEFORE confirming Auth deletion!
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteError) {
      console.error(`Failed to delete user in auth.admin for ${userId}:`, deleteError);
      return new Response(
        JSON.stringify({
          error: `Account deletion failed: ${deleteError.message}. Your account was not deleted. Please try again.`,
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Success confirmation
    return new Response(
      JSON.stringify({
        success: true,
        status: "deleted",
        message: "Your MELSAVA account and associated personal data have been permanently deleted.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "An unexpected error occurred during account deletion." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
