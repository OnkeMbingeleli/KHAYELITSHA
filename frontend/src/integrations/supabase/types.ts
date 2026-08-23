export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      app_settings: {
        Row: {
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      branches: {
        Row: {
          code: string
          created_at: string
          id: string
          name: string
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      loads: {
        Row: {
          branch_id: string
          comment: string | null
          direction: Database["public"]["Enums"]["load_direction"]
          id: string
          marshal_id: string | null
          number_plate: string
          overload: boolean
          rank_id: string
          recorded_at: string
          route_id: string
          seats_loaded: number
          vehicle_id: string | null
        }
        Insert: {
          branch_id: string
          comment?: string | null
          direction?: Database["public"]["Enums"]["load_direction"]
          id?: string
          marshal_id?: string | null
          number_plate: string
          overload?: boolean
          rank_id: string
          recorded_at?: string
          route_id: string
          seats_loaded?: number
          vehicle_id?: string | null
        }
        Update: {
          branch_id?: string
          comment?: string | null
          direction?: Database["public"]["Enums"]["load_direction"]
          id?: string
          marshal_id?: string | null
          number_plate?: string
          overload?: boolean
          rank_id?: string
          recorded_at?: string
          route_id?: string
          seats_loaded?: number
          vehicle_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "loads_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loads_rank_id_fkey"
            columns: ["rank_id"]
            isOneToOne: false
            referencedRelation: "ranks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loads_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loads_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      marshal_assignments: {
        Row: {
          active: boolean
          branch_id: string
          created_at: string
          id: string
          rank_id: string | null
          route_id: string
          user_id: string
        }
        Insert: {
          active?: boolean
          branch_id: string
          created_at?: string
          id?: string
          rank_id?: string | null
          route_id: string
          user_id: string
        }
        Update: {
          active?: boolean
          branch_id?: string
          created_at?: string
          id?: string
          rank_id?: string | null
          route_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "marshal_assignments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marshal_assignments_rank_id_fkey"
            columns: ["rank_id"]
            isOneToOne: false
            referencedRelation: "ranks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "marshal_assignments_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
        ]
      }
      owners: {
        Row: {
          approved_at: string | null
          branch_id: string
          contact: string
          created_at: string
          date_of_birth: string | null
          email: string
          full_name: string
          id: string
          id_number: string
          owner_code: string | null
          status: Database["public"]["Enums"]["owner_status"]
          surname: string
        }
        Insert: {
          approved_at?: string | null
          branch_id: string
          contact: string
          created_at?: string
          date_of_birth?: string | null
          email: string
          full_name: string
          id?: string
          id_number: string
          owner_code?: string | null
          status?: Database["public"]["Enums"]["owner_status"]
          surname: string
        }
        Update: {
          approved_at?: string | null
          branch_id?: string
          contact?: string
          created_at?: string
          date_of_birth?: string | null
          email?: string
          full_name?: string
          id?: string
          id_number?: string
          owner_code?: string | null
          status?: Database["public"]["Enums"]["owner_status"]
          surname?: string
        }
        Relationships: [
          {
            foreignKeyName: "owners_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      patrol_reports: {
        Row: {
          branch_id: string
          description: string
          id: string
          number_plate: string | null
          pass_fail: boolean | null
          patroller_id: string
          rank_id: string | null
          recorded_at: string
          related_load_id: string | null
          report_type: Database["public"]["Enums"]["patrol_report_type"]
          resolution_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          route_id: string | null
          severity: Database["public"]["Enums"]["patrol_severity"]
          status: Database["public"]["Enums"]["patrol_status"]
          vehicle_id: string | null
        }
        Insert: {
          branch_id: string
          description: string
          id?: string
          number_plate?: string | null
          pass_fail?: boolean | null
          patroller_id: string
          rank_id?: string | null
          recorded_at?: string
          related_load_id?: string | null
          report_type: Database["public"]["Enums"]["patrol_report_type"]
          resolution_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          severity?: Database["public"]["Enums"]["patrol_severity"]
          status?: Database["public"]["Enums"]["patrol_status"]
          vehicle_id?: string | null
        }
        Update: {
          branch_id?: string
          description?: string
          id?: string
          number_plate?: string | null
          pass_fail?: boolean | null
          patroller_id?: string
          rank_id?: string | null
          recorded_at?: string
          related_load_id?: string | null
          report_type?: Database["public"]["Enums"]["patrol_report_type"]
          resolution_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          route_id?: string | null
          severity?: Database["public"]["Enums"]["patrol_severity"]
          status?: Database["public"]["Enums"]["patrol_status"]
          vehicle_id?: string | null
        }
        Relationships: []
      }
      patroller_assignments: {
        Row: {
          active: boolean
          branch_id: string
          created_at: string
          id: string
          rank_id: string | null
          route_id: string | null
          user_id: string
        }
        Insert: {
          active?: boolean
          branch_id: string
          created_at?: string
          id?: string
          rank_id?: string | null
          route_id?: string | null
          user_id: string
        }
        Update: {
          active?: boolean
          branch_id?: string
          created_at?: string
          id?: string
          rank_id?: string | null
          route_id?: string | null
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          contact: string | null
          created_at: string
          email: string | null
          full_name: string | null
          id: string
          id_number: string | null
          surname: string | null
        }
        Insert: {
          contact?: string | null
          created_at?: string
          email?: string | null
          full_name?: string | null
          id: string
          id_number?: string | null
          surname?: string | null
        }
        Update: {
          contact?: string | null
          created_at?: string
          email?: string | null
          full_name?: string | null
          id?: string
          id_number?: string | null
          surname?: string | null
        }
        Relationships: []
      }
      rank_routes: {
        Row: {
          rank_id: string
          route_id: string
        }
        Insert: {
          rank_id: string
          route_id: string
        }
        Update: {
          rank_id?: string
          route_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "rank_routes_rank_id_fkey"
            columns: ["rank_id"]
            isOneToOne: false
            referencedRelation: "ranks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rank_routes_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
        ]
      }
      ranks: {
        Row: {
          branch_id: string
          code: string
          created_at: string
          id: string
          is_main: boolean
          name: string
        }
        Insert: {
          branch_id: string
          code: string
          created_at?: string
          id?: string
          is_main?: boolean
          name: string
        }
        Update: {
          branch_id?: string
          code?: string
          created_at?: string
          id?: string
          is_main?: boolean
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "ranks_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      routes: {
        Row: {
          branch_id: string
          code: string
          created_at: string
          id: string
          name: string
        }
        Insert: {
          branch_id: string
          code: string
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          branch_id?: string
          code?: string
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "routes_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      subhead_offices: {
        Row: {
          access_code_hash: string
          access_code_salt: string
          branch_id: string
          created_at: string
          id: string
          lat: number
          lng: number
          name: string
          route_id: string
          town: string | null
          updated_at: string
        }
        Insert: {
          access_code_hash: string
          access_code_salt: string
          branch_id: string
          created_at?: string
          id?: string
          lat?: number
          lng?: number
          name: string
          route_id: string
          town?: string | null
          updated_at?: string
        }
        Update: {
          access_code_hash?: string
          access_code_salt?: string
          branch_id?: string
          created_at?: string
          id?: string
          lat?: number
          lng?: number
          name?: string
          route_id?: string
          town?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      subhead_sessions: {
        Row: {
          created_at: string
          device_token: string
          id: string
          last_seen_at: string
          office_id: string
          user_agent: string | null
        }
        Insert: {
          created_at?: string
          device_token: string
          id?: string
          last_seen_at?: string
          office_id: string
          user_agent?: string | null
        }
        Update: {
          created_at?: string
          device_token?: string
          id?: string
          last_seen_at?: string
          office_id?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "subhead_sessions_office_id_fkey"
            columns: ["office_id"]
            isOneToOne: false
            referencedRelation: "subhead_offices"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      vehicles: {
        Row: {
          active: boolean
          branch_id: string
          created_at: string
          id: string
          make: string | null
          model: string | null
          number_plate: string
          owner_id: string
          primary_route_id: string | null
          qr_token: string
          seats: number
        }
        Insert: {
          active?: boolean
          branch_id: string
          created_at?: string
          id?: string
          make?: string | null
          model?: string | null
          number_plate: string
          owner_id: string
          primary_route_id?: string | null
          qr_token?: string
          seats?: number
        }
        Update: {
          active?: boolean
          branch_id?: string
          created_at?: string
          id?: string
          make?: string | null
          model?: string | null
          number_plate?: string
          owner_id?: string
          primary_route_id?: string | null
          qr_token?: string
          seats?: number
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vehicles_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "owners"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vehicles_primary_route_id_fkey"
            columns: ["primary_route_id"]
            isOneToOne: false
            referencedRelation: "routes"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_patroller: { Args: { _user_id: string }; Returns: boolean }
      is_staff: { Args: { _user_id: string }; Returns: boolean }
    }
    Enums: {
      app_role: "super_admin" | "management" | "marshal" | "patroller"
      load_direction: "outbound" | "inbound"
      owner_status: "pending" | "approved" | "suspended"
      patrol_report_type:
        | "overload"
        | "misconduct"
        | "roadworthy"
        | "marshal_oversight"
      patrol_severity: "low" | "medium" | "high"
      patrol_status: "open" | "reviewed" | "resolved"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["super_admin", "management", "marshal", "patroller"],
      load_direction: ["outbound", "inbound"],
      owner_status: ["pending", "approved", "suspended"],
      patrol_report_type: [
        "overload",
        "misconduct",
        "roadworthy",
        "marshal_oversight",
      ],
      patrol_severity: ["low", "medium", "high"],
      patrol_status: ["open", "reviewed", "resolved"],
    },
  },
} as const
