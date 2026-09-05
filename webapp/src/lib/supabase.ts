// Legacy import path, kept during the Phase 1 rebuild. New code should import
// createClient from "@/lib/supabase/client" (or "@/lib/supabase/server" on
// the server) directly — this file is removed once every page under
// src/app is rebuilt per docs/MOBILE_UI_SPEC.md.
import { createClient } from "./supabase/client";

export const supabase = createClient();
