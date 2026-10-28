export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type PlanTier = 'free' | 'pro' | 'ultra' | 'business';
export type TeamRole = 'owner' | 'admin' | 'editor' | 'viewer';
export type TeamMemberStatus = 'pending' | 'accepted' | 'declined';
export type AdType = 'countdown_overlay' | 'sticky_banner' | 'interstitial';

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          display_name: string | null;
          avatar_url: string | null;
          current_plan: PlanTier;
          storage_used_bytes: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          display_name?: string | null;
          avatar_url?: string | null;
          current_plan?: PlanTier;
          storage_used_bytes?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          display_name?: string | null;
          avatar_url?: string | null;
          current_plan?: PlanTier;
          storage_used_bytes?: number;
          updated_at?: string;
        };
      };
      teams: {
        Row: {
          id: string;
          name: string;
          owner_id: string;
          plan: PlanTier;
          max_members: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          owner_id: string;
          plan?: PlanTier;
          max_members?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          name?: string;
          owner_id?: string;
          plan?: PlanTier;
          max_members?: number;
          updated_at?: string;
        };
      };
      team_members: {
        Row: {
          id: string;
          team_id: string;
          user_id: string | null;
          invited_email: string;
          role: TeamRole;
          status: TeamMemberStatus;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          team_id: string;
          user_id?: string | null;
          invited_email: string;
          role?: TeamRole;
          status?: TeamMemberStatus;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          user_id?: string | null;
          invited_email?: string;
          role?: TeamRole;
          status?: TeamMemberStatus;
          updated_at?: string;
        };
      };
      catalogs: {
        Row: {
          id: string;
          user_id: string;
          team_id: string | null;
          slug: string;
          title: string;
          file_name: string;
          pdf_url: string;
          storage_key: string;
          file_size_bytes: number;
          page_count: number;
          bg_type: string;
          bg_value: string;
          is_floating: boolean;
          is_public: boolean;
          allow_indexing: boolean;
          seo_description: string | null;
          ad_enabled: boolean;
          total_views: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          team_id?: string | null;
          slug: string;
          title: string;
          file_name: string;
          pdf_url: string;
          storage_key: string;
          file_size_bytes?: number;
          page_count?: number;
          bg_type?: string;
          bg_value?: string;
          is_floating?: boolean;
          is_public?: boolean;
          allow_indexing?: boolean;
          seo_description?: string | null;
          ad_enabled?: boolean;
          total_views?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          team_id?: string | null;
          slug?: string;
          title?: string;
          file_name?: string;
          pdf_url?: string;
          storage_key?: string;
          file_size_bytes?: number;
          page_count?: number;
          bg_type?: string;
          bg_value?: string;
          is_floating?: boolean;
          is_public?: boolean;
          allow_indexing?: boolean;
          seo_description?: string | null;
          ad_enabled?: boolean;
          total_views?: number;
          updated_at?: string;
        };
      };
      catalog_page_stats: {
        Row: {
          id: string;
          catalog_id: string;
          page_number: number;
          view_count: number;
          total_duration_seconds: number;
          avg_duration_seconds: number;
          updated_at: string;
        };
        Insert: {
          id?: string;
          catalog_id: string;
          page_number: number;
          view_count?: number;
          total_duration_seconds?: number;
          avg_duration_seconds?: number;
          updated_at?: string;
        };
        Update: {
          view_count?: number;
          total_duration_seconds?: number;
          avg_duration_seconds?: number;
          updated_at?: string;
        };
      };
      page_analytics_logs: {
        Row: {
          id: string;
          catalog_id: string;
          page_number: number;
          session_id: string;
          duration_seconds: number;
          device_type: string;
          user_agent: string | null;
          referrer: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          catalog_id: string;
          page_number: number;
          session_id: string;
          duration_seconds: number;
          device_type?: string;
          user_agent?: string | null;
          referrer?: string | null;
          created_at?: string;
        };
        Update: {
          catalog_id?: string;
          page_number?: number;
          session_id?: string;
          duration_seconds?: number;
          device_type?: string;
          user_agent?: string | null;
          referrer?: string | null;
        };
      };
      ad_campaigns: {
        Row: {
          id: string;
          title: string;
          sponsor_name: string;
          banner_image_url: string;
          target_url: string;
          ad_type: AdType;
          duration_seconds: number;
          is_active: boolean;
          impressions: number;
          clicks: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          sponsor_name: string;
          banner_image_url: string;
          target_url: string;
          ad_type?: AdType;
          duration_seconds?: number;
          is_active?: boolean;
          impressions?: number;
          clicks?: number;
          created_at?: string;
        };
        Update: {
          title?: string;
          sponsor_name?: string;
          banner_image_url?: string;
          target_url?: string;
          ad_type?: AdType;
          duration_seconds?: number;
          is_active?: boolean;
          impressions?: number;
          clicks?: number;
        };
      };
    };
    Functions: {
      record_page_stay_time: {
        Args: {
          p_catalog_id: string;
          p_page_number: number;
          p_duration_seconds: number;
          p_session_id: string;
          p_device_type?: string;
          p_user_agent?: string;
          p_referrer?: string;
        };
        Returns: void;
      };
    };
    Views: {
      [_ in never]: never;
    };
    Enums: {
      plan_tier: PlanTier;
      team_role: TeamRole;
      team_member_status: TeamMemberStatus;
      ad_type: AdType;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}
