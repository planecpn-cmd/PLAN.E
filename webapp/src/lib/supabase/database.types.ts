// Hand-authored from docs/BACKEND_SCHEMA.md — covers Phase 1 tables only.
// Do not run migrations or alter this schema from the web app; it is a read/write
// client contract against the existing hosted Supabase project shared with mobile.

export type Json = string | number | boolean | null | { [key: string]: Json } | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          phone: string | null;
          avatar_url: string | null;
          location: string | null;
          bio: string | null;
          role: "traveler" | "host_applicant" | "host" | "admin";
          language: string;
          points: number;
          onboarding_complete: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["profiles"]["Row"]> & { id: string };
        Update: Partial<Database["public"]["Tables"]["profiles"]["Row"]>;
        Relationships: [];
      };
      interests: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string | null;
          icon: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["interests"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["interests"]["Row"]>;
        Relationships: [];
      };
      regions: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string | null;
          cover_image_url: string | null;
          description: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["regions"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["regions"]["Row"]>;
        Relationships: [];
      };
      categories: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string | null;
          icon: string | null;
          cover_image_url: string | null;
          family_id: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["categories"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["categories"]["Row"]>;
        Relationships: [];
      };
      experience_families: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string;
          description: string | null;
          icon: string | null;
          cover_image_url: string | null;
          sort_order: number;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["experience_families"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["experience_families"]["Row"]>;
        Relationships: [];
      };
      experiences: {
        Row: {
          id: string;
          host_id: string | null;
          category_id: string | null;
          region_id: string | null;
          title: string;
          slug: string;
          summary: string | null;
          description: string | null;
          cover_image_url: string;
          gallery: string[] | null;
          location_name: string | null;
          meeting_point: string | null;
          lat: number | null;
          lng: number | null;
          duration_hours: number | null;
          difficulty: "easy" | "moderate" | "challenging" | "strenuous" | null;
          max_altitude_m: number | null;
          group_size_min: number | null;
          group_size_max: number | null;
          min_age: number | null;
          price_paisa: number;
          child_price_paisa: number | null;
          currency: string;
          included: string[] | null;
          bring_list: string[] | null;
          things_to_know: string[] | null;
          permits_required: string[] | null;
          best_season: number[] | null;
          rating_avg: number;
          rating_count: number;
          status: "draft" | "pending_review" | "published" | "paused" | "archived";
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["experiences"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["experiences"]["Row"]>;
        Relationships: [];
      };
      experience_departures: {
        Row: {
          id: string;
          experience_id: string;
          start_date: string;
          end_date: string;
          total_spots: number;
          spots_left: number;
          price_override_paisa: number | null;
          status: string;
        };
        Insert: Partial<Database["public"]["Tables"]["experience_departures"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["experience_departures"]["Row"]>;
        Relationships: [];
      };
      itinerary_items: {
        Row: {
          id: string;
          experience_id: string;
          day_number: number;
          start_time: string | null;
          title: string;
          description: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["itinerary_items"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["itinerary_items"]["Row"]>;
        Relationships: [];
      };
      reviews: {
        Row: {
          id: string;
          booking_id: string;
          experience_id: string;
          user_id: string;
          rating: number;
          title: string | null;
          body: string | null;
          photos: string[] | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["reviews"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["reviews"]["Row"]>;
        Relationships: [];
      };
      saved_experiences: {
        Row: {
          user_id: string;
          experience_id: string;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["saved_experiences"]["Row"]> & {
          user_id: string;
          experience_id: string;
        };
        Update: Partial<Database["public"]["Tables"]["saved_experiences"]["Row"]>;
        Relationships: [];
      };
      bookings: {
        Row: {
          id: string;
          booking_ref: string;
          user_id: string;
          experience_id: string;
          departure_id: string;
          adults: number;
          children: number;
          addons: Json;
          contact_name: string;
          contact_phone: string;
          subtotal_paisa: number;
          addons_paisa: number;
          fees_paisa: number;
          total_paisa: number;
          status: "pending" | "confirmed" | "cancellation_requested" | "cancelled" | "completed" | "expired";
          quote_expires_at: string | null;
          is_draft: boolean;
          cancelled_at: string | null;
          completed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["bookings"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["bookings"]["Row"]>;
        Relationships: [];
      };
      booking_participants: {
        Row: {
          id: string;
          booking_id: string;
          full_name: string;
          age: number | null;
          is_lead: boolean;
        };
        Insert: Partial<Database["public"]["Tables"]["booking_participants"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["booking_participants"]["Row"]>;
        Relationships: [];
      };
      legal_documents: {
        Row: {
          id: string;
          slug: string;
          version: string;
          locale: string;
          title: string;
          body_md: string;
          effective_at: string;
          requires_acceptance: boolean;
          is_current: boolean;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["legal_documents"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["legal_documents"]["Row"]>;
        Relationships: [];
      };
      legal_acceptances: {
        Row: {
          id: string;
          user_id: string;
          document_id: string;
          booking_id: string | null;
          accepted_at: string;
          client: "flutter" | "web";
          app_version: string | null;
          ip_address: string | null;
        };
        Insert: {
          user_id: string;
          document_id: string;
          booking_id?: string | null;
          accepted_at?: string;
          client: "flutter" | "web";
          app_version?: string | null;
        };
        // RLS forbids UPDATE for non-service roles; typed loose to satisfy the
        // client generics only.
        Update: Partial<Database["public"]["Tables"]["legal_acceptances"]["Row"]>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
  };
}
