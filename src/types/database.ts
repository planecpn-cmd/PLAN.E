export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type UserRole = 'traveler' | 'host_applicant' | 'host' | 'admin';
export type DifficultyLevel = 'easy' | 'moderate' | 'challenging' | 'strenuous';
export type ExperienceStatus = 'draft' | 'pending_review' | 'published' | 'paused' | 'archived';
export type BookingStatus = 'pending' | 'confirmed' | 'cancellation_requested' | 'cancelled' | 'completed' | 'expired';
export type PaymentStatus = 'initiated' | 'paid' | 'failed' | 'refunded';
export type PaymentProvider = 'khalti' | 'esewa';
export type HostAppStatus = 'draft' | 'submitted' | 'under_review' | 'verification' | 'approved' | 'rejected';
export type TripRole = 'traveler' | 'host';
export type NotifType = 'booking' | 'chat' | 'host_application' | 'system' | 'promo';

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
          role: UserRole;
          language: 'en' | 'ne';
          points: number;
          onboarding_complete: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          phone?: string | null;
          avatar_url?: string | null;
          location?: string | null;
          bio?: string | null;
          role?: UserRole;
          language?: 'en' | 'ne';
          points?: number;
          onboarding_complete?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>;
      };
      interests: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string;
          icon: string | null;
          sort_order: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          slug: string;
          name_en: string;
          name_ne: string;
          icon?: string | null;
          sort_order?: number;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['interests']['Insert']>;
      };
      user_interests: {
        Row: {
          user_id: string;
          interest_id: string;
          created_at: string;
        };
        Insert: {
          user_id: string;
          interest_id: string;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['user_interests']['Insert']>;
      };
      regions: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string;
          cover_image_url: string | null;
          description: string | null;
          sort_order: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          slug: string;
          name_en: string;
          name_ne: string;
          cover_image_url?: string | null;
          description?: string | null;
          sort_order?: number;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['regions']['Insert']>;
      };
      categories: {
        Row: {
          id: string;
          slug: string;
          name_en: string;
          name_ne: string;
          icon: string | null;
          cover_image_url: string | null;
          sort_order: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          slug: string;
          name_en: string;
          name_ne: string;
          icon?: string | null;
          cover_image_url?: string | null;
          sort_order?: number;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['categories']['Insert']>;
      };
      experiences: {
        Row: {
          id: string;
          host_id: string | null;
          category_id: string;
          region_id: string;
          title: string;
          slug: string;
          summary: string | null;
          description: string | null;
          cover_image_url: string;
          gallery: string[];
          location_name: string | null;
          meeting_point: string | null;
          lat: number | null;
          lng: number | null;
          duration_hours: number;
          difficulty: DifficultyLevel;
          max_altitude_m: number | null;
          group_size_min: number;
          group_size_max: number;
          min_age: number;
          price_paisa: number;
          child_price_paisa: number | null;
          currency: 'NPR';
          included: string[];
          bring_list: string[];
          things_to_know: string[];
          permits_required: string[];
          best_season: number[];
          rating_avg: number;
          rating_count: number;
          status: ExperienceStatus;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          host_id?: string | null;
          category_id: string;
          region_id: string;
          title: string;
          slug: string;
          summary?: string | null;
          description?: string | null;
          cover_image_url: string;
          gallery?: string[];
          location_name?: string | null;
          meeting_point?: string | null;
          lat?: number | null;
          lng?: number | null;
          duration_hours?: number;
          difficulty?: DifficultyLevel;
          max_altitude_m?: number | null;
          group_size_min?: number;
          group_size_max?: number;
          min_age?: number;
          price_paisa: number;
          child_price_paisa?: number | null;
          currency?: 'NPR';
          included?: string[];
          bring_list?: string[];
          things_to_know?: string[];
          permits_required?: string[];
          best_season?: number[];
          rating_avg?: number;
          rating_count?: number;
          status?: ExperienceStatus;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['experiences']['Insert']>;
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
          created_at: string;
        };
        Insert: {
          id?: string;
          experience_id: string;
          start_date: string;
          end_date: string;
          total_spots: number;
          spots_left: number;
          price_override_paisa?: number | null;
          status?: string;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['experience_departures']['Insert']>;
      };
      saved_experiences: {
        Row: {
          user_id: string;
          experience_id: string;
          created_at: string;
        };
        Insert: {
          user_id: string;
          experience_id: string;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['saved_experiences']['Insert']>;
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
          status: BookingStatus;
          quote_expires_at: string | null;
          is_draft: boolean;
          cancelled_at: string | null;
          completed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          booking_ref: string;
          user_id: string;
          experience_id: string;
          departure_id: string;
          adults: number;
          children?: number;
          addons?: Json;
          contact_name: string;
          contact_phone: string;
          subtotal_paisa: number;
          addons_paisa?: number;
          fees_paisa?: number;
          total_paisa: number;
          status?: BookingStatus;
          quote_expires_at?: string | null;
          is_draft?: boolean;
          cancelled_at?: string | null;
          completed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['bookings']['Insert']>;
      };
      payments: {
        Row: {
          id: string;
          booking_id: string;
          provider: PaymentProvider;
          provider_ref: string | null;
          idempotency_key: string;
          amount_paisa: number;
          status: PaymentStatus;
          raw_response: Json;
          paid_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          booking_id: string;
          provider: PaymentProvider;
          provider_ref?: string | null;
          idempotency_key: string;
          amount_paisa: number;
          status?: PaymentStatus;
          raw_response?: Json;
          paid_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['payments']['Insert']>;
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
          photos: string[];
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          booking_id: string;
          experience_id: string;
          user_id: string;
          rating: number;
          title?: string | null;
          body?: string | null;
          photos?: string[];
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['reviews']['Insert']>;
      };
      host_applications: {
        Row: {
          id: string;
          user_id: string;
          status: HostAppStatus;
          current_step: number;
          category_id: string | null;
          title: string | null;
          description: string | null;
          location: string | null;
          photos: string[];
          verification_doc_path: string | null;
          submitted_at: string | null;
          reviewed_at: string | null;
          reviewer_note: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          status?: HostAppStatus;
          current_step?: number;
          category_id?: string | null;
          title?: string | null;
          description?: string | null;
          location?: string | null;
          photos?: string[];
          verification_doc_path?: string | null;
          submitted_at?: string | null;
          reviewed_at?: string | null;
          reviewer_note?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['host_applications']['Insert']>;
      };
    };
  };
}
