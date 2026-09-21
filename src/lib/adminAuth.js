import { supabase } from "./supabase.js";

export async function requireAdminSession() {
    const {
        data: { session },
    } = await supabase.auth.getSession();

    if (!session) {
        window.location.href = "/admin/login";
        return null;
    }

    return session;
}
