-- Migration 0002: Enums
create type user_role         as enum ('traveler','host_applicant','host','admin');
create type difficulty_level  as enum ('easy','moderate','challenging','strenuous');
create type experience_status as enum ('draft','pending_review','published','paused','archived');
create type booking_status    as enum ('pending','confirmed','cancellation_requested','cancelled','completed','expired');
create type payment_status    as enum ('initiated','paid','failed','refunded');
create type payment_provider  as enum ('khalti','esewa');
create type host_app_status   as enum ('draft','submitted','under_review','verification','approved','rejected');
create type trip_role         as enum ('traveler','host');
create type notif_type        as enum ('booking','chat','host_application','system','promo');
