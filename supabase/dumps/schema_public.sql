


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."booking_status" AS ENUM (
    'pending',
    'confirmed',
    'cancellation_requested',
    'cancelled',
    'completed',
    'expired'
);


ALTER TYPE "public"."booking_status" OWNER TO "postgres";


CREATE TYPE "public"."difficulty_level" AS ENUM (
    'easy',
    'moderate',
    'challenging',
    'strenuous'
);


ALTER TYPE "public"."difficulty_level" OWNER TO "postgres";


CREATE TYPE "public"."experience_status" AS ENUM (
    'draft',
    'pending_review',
    'published',
    'paused',
    'archived'
);


ALTER TYPE "public"."experience_status" OWNER TO "postgres";


CREATE TYPE "public"."host_app_status" AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'verification',
    'approved',
    'rejected'
);


ALTER TYPE "public"."host_app_status" OWNER TO "postgres";


CREATE TYPE "public"."notif_type" AS ENUM (
    'booking',
    'chat',
    'host_application',
    'system',
    'promo'
);


ALTER TYPE "public"."notif_type" OWNER TO "postgres";


CREATE TYPE "public"."payment_provider" AS ENUM (
    'khalti',
    'esewa'
);


ALTER TYPE "public"."payment_provider" OWNER TO "postgres";


CREATE TYPE "public"."payment_status" AS ENUM (
    'initiated',
    'paid',
    'failed',
    'refunded'
);


ALTER TYPE "public"."payment_status" OWNER TO "postgres";


CREATE TYPE "public"."trip_role" AS ENUM (
    'traveler',
    'host'
);


ALTER TYPE "public"."trip_role" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'traveler',
    'host_applicant',
    'host',
    'admin'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."experiences_update_search_tsv"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.search_tsv := setweight(to_tsvector('english', coalesce(new.title, '')), 'A') ||
                    setweight(to_tsvector('english', coalesce(new.summary, '')), 'B') ||
                    setweight(to_tsvector('english', coalesce(new.location_name, '')), 'C');
  return new;
end;
$$;


ALTER FUNCTION "public"."experiences_update_search_tsv"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Traveler'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_trip_member"("p_booking_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_user_id uuid;
  v_is_owner boolean;
  v_is_host boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then return false; end if;

  select exists (
    select 1 from public.bookings b where b.id = p_booking_id and b.user_id = v_user_id
  ) into v_is_owner;

  if v_is_owner then return true; end if;

  select exists (
    select 1 from public.bookings b
    join public.experiences e on e.id = b.experience_id
    where b.id = p_booking_id and e.host_id = v_user_id
  ) into v_is_host;

  return v_is_host;
end;
$$;


ALTER FUNCTION "public"."is_trip_member"("p_booking_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_client_booking_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: booking status updates are restricted to service role';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."prevent_client_booking_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_client_host_app_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: host application status updates are restricted to service role';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."prevent_client_host_app_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_client_payment_mutation"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: payments table is service role only';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."prevent_client_payment_mutation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_profile_role_escalation"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if old.role <> new.role and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: cannot alter profile role directly';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."prevent_profile_role_escalation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_experience_rating_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_exp_id uuid;
begin
  if (TG_OP = 'DELETE') then
    v_exp_id := old.experience_id;
  else
    v_exp_id := new.experience_id;
  end if;

  update public.experiences
  set
    rating_avg = coalesce((select round(avg(rating)::numeric, 1) from public.reviews where experience_id = v_exp_id), 0.0),
    rating_count = (select count(*) from public.reviews where experience_id = v_exp_id)
  where id = v_exp_id;

  return null;
end;
$$;


ALTER FUNCTION "public"."update_experience_rating_stats"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."booking_participants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "age" integer,
    "is_lead" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."booking_participants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_ref" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "experience_id" "uuid" NOT NULL,
    "departure_id" "uuid" NOT NULL,
    "adults" integer NOT NULL,
    "children" integer DEFAULT 0 NOT NULL,
    "addons" "jsonb" DEFAULT '[]'::"jsonb",
    "contact_name" "text" NOT NULL,
    "contact_phone" "text" NOT NULL,
    "subtotal_paisa" bigint NOT NULL,
    "addons_paisa" bigint DEFAULT 0 NOT NULL,
    "fees_paisa" bigint DEFAULT 0 NOT NULL,
    "total_paisa" bigint NOT NULL,
    "status" "public"."booking_status" DEFAULT 'pending'::"public"."booking_status" NOT NULL,
    "quote_expires_at" timestamp with time zone,
    "is_draft" boolean DEFAULT false,
    "cancelled_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "bookings_addons_paisa_check" CHECK (("addons_paisa" >= 0)),
    CONSTRAINT "bookings_adults_check" CHECK (("adults" >= 1)),
    CONSTRAINT "bookings_children_check" CHECK (("children" >= 0)),
    CONSTRAINT "bookings_fees_paisa_check" CHECK (("fees_paisa" >= 0)),
    CONSTRAINT "bookings_subtotal_paisa_check" CHECK (("subtotal_paisa" >= 0)),
    CONSTRAINT "bookings_total_paisa_check" CHECK (("total_paisa" >= 0))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."budget_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "label" "text" NOT NULL,
    "amount_paisa" bigint NOT NULL,
    "category" "text",
    "spent_on" "date" DEFAULT CURRENT_DATE,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "budget_entries_amount_paisa_check" CHECK (("amount_paisa" >= 0))
);


ALTER TABLE "public"."budget_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name_en" "text" NOT NULL,
    "name_ne" "text" NOT NULL,
    "icon" "text",
    "cover_image_url" "text",
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."device_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "expo_push_token" "text" NOT NULL,
    "platform" "text",
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."experience_departures" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "experience_id" "uuid" NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date" NOT NULL,
    "total_spots" integer NOT NULL,
    "spots_left" integer NOT NULL,
    "price_override_paisa" bigint,
    "status" "text" DEFAULT 'open'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "experience_departures_price_override_paisa_check" CHECK ((("price_override_paisa" IS NULL) OR ("price_override_paisa" >= 0))),
    CONSTRAINT "experience_departures_spots_left_check" CHECK (("spots_left" >= 0)),
    CONSTRAINT "experience_departures_total_spots_check" CHECK (("total_spots" > 0))
);


ALTER TABLE "public"."experience_departures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."experiences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "host_id" "uuid",
    "category_id" "uuid",
    "region_id" "uuid",
    "title" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "summary" "text",
    "description" "text",
    "cover_image_url" "text" NOT NULL,
    "gallery" "text"[] DEFAULT '{}'::"text"[],
    "location_name" "text",
    "meeting_point" "text",
    "lat" double precision,
    "lng" double precision,
    "duration_hours" integer DEFAULT 24 NOT NULL,
    "difficulty" "public"."difficulty_level" DEFAULT 'moderate'::"public"."difficulty_level" NOT NULL,
    "max_altitude_m" integer,
    "group_size_min" integer DEFAULT 1,
    "group_size_max" integer DEFAULT 12,
    "min_age" integer DEFAULT 10,
    "price_paisa" bigint NOT NULL,
    "child_price_paisa" bigint,
    "currency" "text" DEFAULT 'NPR'::"text" NOT NULL,
    "included" "text"[] DEFAULT '{}'::"text"[],
    "bring_list" "text"[] DEFAULT '{}'::"text"[],
    "things_to_know" "text"[] DEFAULT '{}'::"text"[],
    "permits_required" "text"[] DEFAULT '{}'::"text"[],
    "best_season" integer[] DEFAULT '{3,4,5,9,10,11}'::integer[],
    "rating_avg" numeric(2,1) DEFAULT 0.0,
    "rating_count" integer DEFAULT 0,
    "status" "public"."experience_status" DEFAULT 'draft'::"public"."experience_status",
    "search_tsv" "tsvector",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "experiences_child_price_paisa_check" CHECK ((("child_price_paisa" IS NULL) OR ("child_price_paisa" >= 0))),
    CONSTRAINT "experiences_currency_check" CHECK (("currency" = 'NPR'::"text")),
    CONSTRAINT "experiences_price_paisa_check" CHECK (("price_paisa" >= 0)),
    CONSTRAINT "experiences_rating_avg_check" CHECK ((("rating_avg" >= (0)::numeric) AND ("rating_avg" <= 5.0))),
    CONSTRAINT "experiences_rating_count_check" CHECK (("rating_count" >= 0))
);


ALTER TABLE "public"."experiences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gear_checklist_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "label" "text" NOT NULL,
    "is_checked" boolean DEFAULT false NOT NULL,
    "is_custom" boolean DEFAULT false NOT NULL,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."gear_checklist_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."host_applications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "public"."host_app_status" DEFAULT 'draft'::"public"."host_app_status" NOT NULL,
    "current_step" integer DEFAULT 1 NOT NULL,
    "category_id" "uuid",
    "title" "text",
    "description" "text",
    "location" "text",
    "photos" "text"[] DEFAULT '{}'::"text"[],
    "verification_doc_path" "text",
    "submitted_at" timestamp with time zone,
    "reviewed_at" timestamp with time zone,
    "reviewer_note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "host_applications_current_step_check" CHECK ((("current_step" >= 1) AND ("current_step" <= 4)))
);


ALTER TABLE "public"."host_applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."interests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name_en" "text" NOT NULL,
    "name_ne" "text" NOT NULL,
    "icon" "text",
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."interests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."itinerary_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "experience_id" "uuid" NOT NULL,
    "day_number" integer NOT NULL,
    "start_time" time without time zone,
    "title" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "itinerary_items_day_number_check" CHECK (("day_number" > 0))
);


ALTER TABLE "public"."itinerary_items" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_plans_upcoming" WITH ("security_invoker"='on') AS
 SELECT "b"."id" AS "booking_id",
    "b"."booking_ref",
    "b"."user_id",
    "b"."status",
    "b"."total_paisa",
    "b"."adults",
    "b"."children",
    "e"."id" AS "experience_id",
    "e"."title" AS "experience_title",
    "e"."cover_image_url",
    "e"."location_name",
    "d"."start_date",
    "d"."end_date"
   FROM (("public"."bookings" "b"
     JOIN "public"."experiences" "e" ON (("e"."id" = "b"."experience_id")))
     JOIN "public"."experience_departures" "d" ON (("d"."id" = "b"."departure_id")))
  WHERE (("b"."status" = 'confirmed'::"public"."booking_status") AND ("d"."start_date" >= CURRENT_DATE));


ALTER VIEW "public"."my_plans_upcoming" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_trips_cancelled" WITH ("security_invoker"='on') AS
 SELECT "b"."id" AS "booking_id",
    "b"."booking_ref",
    "b"."user_id",
    "b"."total_paisa",
    "b"."cancelled_at",
    "e"."id" AS "experience_id",
    "e"."title" AS "experience_title",
    "e"."cover_image_url",
    "e"."location_name"
   FROM ("public"."bookings" "b"
     JOIN "public"."experiences" "e" ON (("e"."id" = "b"."experience_id")))
  WHERE ("b"."status" = 'cancelled'::"public"."booking_status");


ALTER VIEW "public"."my_trips_cancelled" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "experience_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "rating" integer NOT NULL,
    "title" "text",
    "body" "text",
    "photos" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "reviews_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."reviews" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_trips_completed" WITH ("security_invoker"='on') AS
 SELECT "b"."id" AS "booking_id",
    "b"."booking_ref",
    "b"."user_id",
    "b"."total_paisa",
    "b"."completed_at",
    "e"."id" AS "experience_id",
    "e"."title" AS "experience_title",
    "e"."cover_image_url",
    "e"."location_name",
    "r"."id" AS "review_id"
   FROM (("public"."bookings" "b"
     JOIN "public"."experiences" "e" ON (("e"."id" = "b"."experience_id")))
     LEFT JOIN "public"."reviews" "r" ON (("r"."booking_id" = "b"."id")))
  WHERE ("b"."status" = 'completed'::"public"."booking_status");


ALTER VIEW "public"."my_trips_completed" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notif_type" DEFAULT 'system'::"public"."notif_type" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "entity_id" "uuid",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "provider" "public"."payment_provider" NOT NULL,
    "provider_ref" "text",
    "idempotency_key" "text" NOT NULL,
    "amount_paisa" bigint NOT NULL,
    "status" "public"."payment_status" DEFAULT 'initiated'::"public"."payment_status" NOT NULL,
    "raw_response" "jsonb" DEFAULT '{}'::"jsonb",
    "paid_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "payments_amount_paisa_check" CHECK (("amount_paisa" > 0))
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "phone" "text",
    "avatar_url" "text",
    "location" "text",
    "bio" "text",
    "role" "public"."user_role" DEFAULT 'traveler'::"public"."user_role" NOT NULL,
    "language" "text" DEFAULT 'en'::"text",
    "points" integer DEFAULT 0 NOT NULL,
    "onboarding_complete" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "profiles_language_check" CHECK (("language" = ANY (ARRAY['en'::"text", 'ne'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."regions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name_en" "text" NOT NULL,
    "name_ne" "text" NOT NULL,
    "cover_image_url" "text",
    "description" "text",
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."regions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."saved_experiences" (
    "user_id" "uuid" NOT NULL,
    "experience_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."saved_experiences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "body" "text" NOT NULL,
    "attachment_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."trip_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_interests" (
    "user_id" "uuid" NOT NULL,
    "interest_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_interests" OWNER TO "postgres";


ALTER TABLE ONLY "public"."booking_participants"
    ADD CONSTRAINT "booking_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_booking_ref_key" UNIQUE ("booking_ref");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."budget_entries"
    ADD CONSTRAINT "budget_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_expo_push_token_key" UNIQUE ("expo_push_token");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experience_departures"
    ADD CONSTRAINT "experience_departures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."gear_checklist_items"
    ADD CONSTRAINT "gear_checklist_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."host_applications"
    ADD CONSTRAINT "host_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."host_applications"
    ADD CONSTRAINT "host_applications_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."interests"
    ADD CONSTRAINT "interests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."interests"
    ADD CONSTRAINT "interests_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."itinerary_items"
    ADD CONSTRAINT "itinerary_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_booking_id_key" UNIQUE ("booking_id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_idempotency_key_key" UNIQUE ("idempotency_key");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_booking_id_key" UNIQUE ("booking_id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_experiences"
    ADD CONSTRAINT "saved_experiences_pkey" PRIMARY KEY ("user_id", "experience_id");



ALTER TABLE ONLY "public"."trip_messages"
    ADD CONSTRAINT "trip_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experience_departures"
    ADD CONSTRAINT "unique_experience_start_date" UNIQUE ("experience_id", "start_date");



ALTER TABLE ONLY "public"."user_interests"
    ADD CONSTRAINT "user_interests_pkey" PRIMARY KEY ("user_id", "interest_id");



CREATE INDEX "idx_bookings_departure" ON "public"."bookings" USING "btree" ("departure_id");



CREATE INDEX "idx_bookings_quote_expiry" ON "public"."bookings" USING "btree" ("status", "quote_expires_at") WHERE ("status" = 'pending'::"public"."booking_status");



CREATE INDEX "idx_bookings_user_status" ON "public"."bookings" USING "btree" ("user_id", "status");



CREATE INDEX "idx_budget_entries_booking" ON "public"."budget_entries" USING "btree" ("booking_id");



CREATE INDEX "idx_departures_exp_date" ON "public"."experience_departures" USING "btree" ("experience_id", "start_date") WHERE ("status" = 'open'::"text");



CREATE INDEX "idx_device_tokens_user" ON "public"."device_tokens" USING "btree" ("user_id");



CREATE INDEX "idx_experiences_rating" ON "public"."experiences" USING "btree" ("rating_avg" DESC);



CREATE INDEX "idx_experiences_search_tsv" ON "public"."experiences" USING "gin" ("search_tsv");



CREATE INDEX "idx_experiences_status_category" ON "public"."experiences" USING "btree" ("status", "category_id");



CREATE INDEX "idx_experiences_status_difficulty" ON "public"."experiences" USING "btree" ("status", "difficulty");



CREATE INDEX "idx_experiences_status_price" ON "public"."experiences" USING "btree" ("status", "price_paisa");



CREATE INDEX "idx_experiences_status_region" ON "public"."experiences" USING "btree" ("status", "region_id");



CREATE INDEX "idx_gear_items_booking" ON "public"."gear_checklist_items" USING "btree" ("booking_id");



CREATE INDEX "idx_itinerary_exp_day" ON "public"."itinerary_items" USING "btree" ("experience_id", "day_number");



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("user_id", "is_read", "created_at" DESC);



CREATE INDEX "idx_participants_booking" ON "public"."booking_participants" USING "btree" ("booking_id");



CREATE INDEX "idx_trip_messages_booking" ON "public"."trip_messages" USING "btree" ("booking_id", "created_at" DESC);



CREATE OR REPLACE TRIGGER "check_booking_status_update" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_client_booking_status_change"();



CREATE OR REPLACE TRIGGER "check_host_app_status_update" BEFORE UPDATE ON "public"."host_applications" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_client_host_app_status_change"();



CREATE OR REPLACE TRIGGER "check_payment_mutation" BEFORE INSERT OR DELETE OR UPDATE ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_client_payment_mutation"();



CREATE OR REPLACE TRIGGER "check_profile_role_update" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_profile_role_escalation"();



CREATE OR REPLACE TRIGGER "experiences_search_tsv_trigger" BEFORE INSERT OR UPDATE ON "public"."experiences" FOR EACH ROW EXECUTE FUNCTION "public"."experiences_update_search_tsv"();



CREATE OR REPLACE TRIGGER "on_review_change" AFTER INSERT OR DELETE OR UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."update_experience_rating_stats"();



CREATE OR REPLACE TRIGGER "set_bookings_updated_at" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_experiences_updated_at" BEFORE UPDATE ON "public"."experiences" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_host_apps_updated_at" BEFORE UPDATE ON "public"."host_applications" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_payments_updated_at" BEFORE UPDATE ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_reviews_updated_at" BEFORE UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."booking_participants"
    ADD CONSTRAINT "booking_participants_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_departure_id_fkey" FOREIGN KEY ("departure_id") REFERENCES "public"."experience_departures"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_experience_id_fkey" FOREIGN KEY ("experience_id") REFERENCES "public"."experiences"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."budget_entries"
    ADD CONSTRAINT "budget_entries_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experience_departures"
    ADD CONSTRAINT "experience_departures_experience_id_fkey" FOREIGN KEY ("experience_id") REFERENCES "public"."experiences"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_host_id_fkey" FOREIGN KEY ("host_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."regions"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."gear_checklist_items"
    ADD CONSTRAINT "gear_checklist_items_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."host_applications"
    ADD CONSTRAINT "host_applications_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."host_applications"
    ADD CONSTRAINT "host_applications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."itinerary_items"
    ADD CONSTRAINT "itinerary_items_experience_id_fkey" FOREIGN KEY ("experience_id") REFERENCES "public"."experiences"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_experience_id_fkey" FOREIGN KEY ("experience_id") REFERENCES "public"."experiences"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_experiences"
    ADD CONSTRAINT "saved_experiences_experience_id_fkey" FOREIGN KEY ("experience_id") REFERENCES "public"."experiences"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_experiences"
    ADD CONSTRAINT "saved_experiences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_messages"
    ADD CONSTRAINT "trip_messages_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_messages"
    ADD CONSTRAINT "trip_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_interests"
    ADD CONSTRAINT "user_interests_interest_id_fkey" FOREIGN KEY ("interest_id") REFERENCES "public"."interests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_interests"
    ADD CONSTRAINT "user_interests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



CREATE POLICY "Booking lead user can insert participants" ON "public"."booking_participants" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "booking_participants"."booking_id") AND ("b"."user_id" = "auth"."uid"())))));



CREATE POLICY "Booking owners can manage budget entries" ON "public"."budget_entries" USING ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "budget_entries"."booking_id") AND ("b"."user_id" = "auth"."uid"())))));



CREATE POLICY "Booking owners can manage gear checklist" ON "public"."gear_checklist_items" USING ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "gear_checklist_items"."booking_id") AND ("b"."user_id" = "auth"."uid"())))));



CREATE POLICY "Categories are readable by everyone" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "Departures readable for published experiences" ON "public"."experience_departures" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."experiences" "e"
  WHERE (("e"."id" = "experience_departures"."experience_id") AND (("e"."status" = 'published'::"public"."experience_status") OR ("e"."host_id" = "auth"."uid"()))))));



CREATE POLICY "Hosts can manage draft or pending experiences" ON "public"."experiences" USING ((("auth"."uid"() = "host_id") AND ("status" = ANY (ARRAY['draft'::"public"."experience_status", 'pending_review'::"public"."experience_status"]))));



CREATE POLICY "Interests are readable by everyone" ON "public"."interests" FOR SELECT USING (true);



CREATE POLICY "Itinerary items readable by anyone" ON "public"."itinerary_items" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."experiences" "e"
  WHERE (("e"."id" = "itinerary_items"."experience_id") AND (("e"."status" = 'published'::"public"."experience_status") OR ("e"."host_id" = "auth"."uid"()))))));



CREATE POLICY "Participants readable by booking owner or host" ON "public"."booking_participants" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "booking_participants"."booking_id") AND (("b"."user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."experiences" "e"
          WHERE (("e"."id" = "b"."experience_id") AND ("e"."host_id" = "auth"."uid"())))))))));



CREATE POLICY "Public profiles are readable by everyone" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Published experiences are readable by anyone" ON "public"."experiences" FOR SELECT USING ((("status" = 'published'::"public"."experience_status") OR ("auth"."uid"() = "host_id")));



CREATE POLICY "Regions are readable by everyone" ON "public"."regions" FOR SELECT USING (true);



CREATE POLICY "Reviews are readable by everyone" ON "public"."reviews" FOR SELECT USING (true);



CREATE POLICY "Trip members can insert trip messages" ON "public"."trip_messages" FOR INSERT WITH CHECK (("public"."is_trip_member"("booking_id") AND ("auth"."uid"() = "sender_id")));



CREATE POLICY "Trip members can read trip messages" ON "public"."trip_messages" FOR SELECT USING ("public"."is_trip_member"("booking_id"));



CREATE POLICY "Users can create and edit draft host applications" ON "public"."host_applications" USING ((("auth"."uid"() = "user_id") AND ("status" = 'draft'::"public"."host_app_status")));



CREATE POLICY "Users can insert pending bookings" ON "public"."bookings" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND ("status" = 'pending'::"public"."booking_status")));



CREATE POLICY "Users can insert review for completed booking" ON "public"."reviews" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "reviews"."booking_id") AND ("b"."user_id" = "auth"."uid"()) AND ("b"."status" = 'completed'::"public"."booking_status"))))));



CREATE POLICY "Users can manage saved experiences" ON "public"."saved_experiences" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their device tokens" ON "public"."device_tokens" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own interests" ON "public"."user_interests" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can mark notifications as read" ON "public"."notifications" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read their own interests" ON "public"."user_interests" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view their own bookings" ON "public"."bookings" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."experiences" "e"
  WHERE (("e"."id" = "bookings"."experience_id") AND ("e"."host_id" = "auth"."uid"()))))));



CREATE POLICY "Users can view their own host application" ON "public"."host_applications" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."booking_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."budget_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."device_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."experience_departures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."experiences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gear_checklist_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."host_applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."interests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."itinerary_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."regions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."saved_experiences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."trip_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_interests" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."booking_participants" TO "anon";
GRANT ALL ON TABLE "public"."booking_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."booking_participants" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."budget_entries" TO "anon";
GRANT ALL ON TABLE "public"."budget_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."budget_entries" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."device_tokens" TO "anon";
GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."experience_departures" TO "anon";
GRANT ALL ON TABLE "public"."experience_departures" TO "authenticated";
GRANT ALL ON TABLE "public"."experience_departures" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."experiences" TO "anon";
GRANT ALL ON TABLE "public"."experiences" TO "authenticated";
GRANT ALL ON TABLE "public"."experiences" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."gear_checklist_items" TO "anon";
GRANT ALL ON TABLE "public"."gear_checklist_items" TO "authenticated";
GRANT ALL ON TABLE "public"."gear_checklist_items" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."host_applications" TO "anon";
GRANT ALL ON TABLE "public"."host_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."host_applications" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."interests" TO "anon";
GRANT ALL ON TABLE "public"."interests" TO "authenticated";
GRANT ALL ON TABLE "public"."interests" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."itinerary_items" TO "anon";
GRANT ALL ON TABLE "public"."itinerary_items" TO "authenticated";
GRANT ALL ON TABLE "public"."itinerary_items" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."my_plans_upcoming" TO "anon";
GRANT ALL ON TABLE "public"."my_plans_upcoming" TO "authenticated";
GRANT ALL ON TABLE "public"."my_plans_upcoming" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."my_trips_cancelled" TO "anon";
GRANT ALL ON TABLE "public"."my_trips_cancelled" TO "authenticated";
GRANT ALL ON TABLE "public"."my_trips_cancelled" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."reviews" TO "anon";
GRANT ALL ON TABLE "public"."reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."reviews" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."my_trips_completed" TO "anon";
GRANT ALL ON TABLE "public"."my_trips_completed" TO "authenticated";
GRANT ALL ON TABLE "public"."my_trips_completed" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."payments" TO "anon";
GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."regions" TO "anon";
GRANT ALL ON TABLE "public"."regions" TO "authenticated";
GRANT ALL ON TABLE "public"."regions" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."saved_experiences" TO "anon";
GRANT ALL ON TABLE "public"."saved_experiences" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_experiences" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."trip_messages" TO "anon";
GRANT ALL ON TABLE "public"."trip_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."trip_messages" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."user_interests" TO "anon";
GRANT ALL ON TABLE "public"."user_interests" TO "authenticated";
GRANT ALL ON TABLE "public"."user_interests" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,USAGE ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,USAGE ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







