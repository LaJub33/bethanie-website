// Supabase Edge Function: subscribe-newsletter
// Reçoit un email depuis le formulaire du site et l'ajoute à une liste Brevo.
// Secrets requis (supabase secrets set ...): BREVO_API_KEY, BREVO_LIST_ID

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY");
const BREVO_LIST_ID = Deno.env.get("BREVO_LIST_ID");

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

Deno.serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response(null, { headers: corsHeaders });
    }

    if (req.method !== "POST") {
        return new Response(JSON.stringify({ error: "Method not allowed" }), {
            status: 405,
            headers: jsonHeaders,
        });
    }

    if (!BREVO_API_KEY || !BREVO_LIST_ID) {
        return new Response(
            JSON.stringify({ error: "Newsletter service misconfigured" }),
            { status: 500, headers: jsonHeaders },
        );
    }

    const body = await req.json().catch(() => null);
    const email = body?.email;

    if (typeof email !== "string" || !EMAIL_REGEX.test(email)) {
        return new Response(JSON.stringify({ error: "Email invalide" }), {
            status: 400,
            headers: jsonHeaders,
        });
    }

    const brevoResponse = await fetch("https://api.brevo.com/v3/contacts", {
        method: "POST",
        headers: {
            "api-key": BREVO_API_KEY,
            "Content-Type": "application/json",
            Accept: "application/json",
        },
        body: JSON.stringify({
            email,
            listIds: [Number(BREVO_LIST_ID)],
            updateEnabled: true,
        }),
    });

    if (brevoResponse.ok) {
        // Brevo renvoie 201 pour une création, 204 (updateEnabled) quand le
        // contact existait déjà et a simplement été mis à jour.
        const alreadySubscribed = brevoResponse.status === 204;

        return new Response(
            JSON.stringify({ success: true, alreadySubscribed }),
            { status: 200, headers: jsonHeaders },
        );
    }

    const errorBody = await brevoResponse.json().catch(() => null);

    // Le contact existe déjà et n'a pas pu être mis à jour -> déjà abonné
    if (errorBody?.code === "duplicate_parameter") {
        return new Response(
            JSON.stringify({ success: true, alreadySubscribed: true }),
            { status: 200, headers: jsonHeaders },
        );
    }

    return new Response(
        JSON.stringify({ error: errorBody?.message ?? "Erreur Brevo" }),
        { status: 502, headers: jsonHeaders },
    );
});
