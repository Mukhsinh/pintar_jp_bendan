export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      m_units: {
        Row: {
          id: string
          code: string
          name: string
          proportion_percentage: number
          remuneration_style: 'score_based' | 'activity_based_pir' | null
          is_active: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          code: string
          name: string
          proportion_percentage?: number
          remuneration_style?: 'score_based' | 'activity_based_pir' | null
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          code?: string
          name?: string
          proportion_percentage?: number
          remuneration_style?: 'score_based' | 'activity_based_pir' | null
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      m_employees: {
        Row: {
          id: string
          user_id: string | null
          employee_code: string
          full_name: string
          unit_id: string
          role: string | null
          email: string | null
          tax_status: string | null
          employment_status: 'PNS' | 'PPPK' | 'PPPK PARUH WAKTU' | 'BLUD' | null
          employee_status: string | null
          tax_type: 'Final' | 'TER' | null
          pns_grade: string | null
          position: string | null
          phone: string | null
          nik: string | null
          bank_name: string | null
          bank_account_number: string | null
          bank_account_name: string | null
          is_active: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id?: string | null
          employee_code: string
          full_name: string
          unit_id: string
          role?: string | null
          email?: string | null
          tax_status?: string | null
          employment_status?: 'PNS' | 'PPPK' | 'PPPK PARUH WAKTU' | 'BLUD' | null
          employee_status?: string | null
          tax_type?: 'Final' | 'TER' | null
          pns_grade?: string | null
          position?: string | null
          phone?: string | null
          nik?: string | null
          bank_name?: string | null
          bank_account_number?: string | null
          bank_account_name?: string | null
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string | null
          employee_code?: string
          full_name?: string
          unit_id?: string
          role?: string | null
          email?: string | null
          tax_status?: string | null
          employment_status?: 'PNS' | 'PPPK' | 'PPPK PARUH WAKTU' | 'BLUD' | null
          employee_status?: string | null
          tax_type?: 'Final' | 'TER' | null
          pns_grade?: string | null
          position?: string | null
          phone?: string | null
          nik?: string | null
          bank_name?: string | null
          bank_account_number?: string | null
          bank_account_name?: string | null
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

// ============================================
// Application Specific Types
// ============================================

export type Role = 'superadmin' | 'unit_manager' | 'employee'

export interface Pegawai {
  id: string
  user_id: string | null
  employee_code: string
  full_name: string
  unit_id: string
  role: Role
  email: string | null
  tax_status: string | null
  employment_status: 'PNS' | 'PPPK' | 'PPPK PARUH WAKTU' | 'BLUD' | null
  employee_status: string | null
  tax_type: 'Final' | 'TER' | null
  pns_grade: string | null
  position: string | null
  phone: string | null
  nik: string | null
  bank_name: string | null
  bank_account_number: string | null
  bank_account_name: string | null
  is_active: boolean
  created_at: string
  updated_at: string
  m_units?: {
    name: string
    code: string
  }
}

export interface UserMetadata {
  role: Role
  full_name?: string
  employee_id?: string
  unit_id?: string
}

export interface UserWithEmployee {
  id: string
  email: string
  role: Role
  employeeId: string
  employeeCode: string
  fullName: string
  unitId: string
  taxStatus: string | null
  isActive: boolean
  createdAt: string
  updatedAt: string
  employee?: Pegawai | null
}

export interface CreateUserInput {
  email: string
  password?: string
  employeeCode: string
  fullName: string
  unitId: string
  role: Role
  taxStatus?: string
}

export interface UpdateUserInput {
  email?: string
  password?: string
  employeeCode?: string
  fullName?: string
  unitId?: string
  role?: Role
  taxStatus?: string
  isActive?: boolean
}

export interface CreatePegawaiData {
  employee_code: string
  full_name: string
  unit_id: string
  position?: string | null
  phone?: string | null
  nik?: string | null
  bank_name?: string | null
  bank_account_number?: string | null
  bank_account_name?: string | null
  tax_status?: string | null
  employment_status?: 'PNS' | 'PPPK' | 'PPPK PARUH WAKTU' | 'BLUD' | null
  employee_status?: string | null
  tax_type?: 'Final' | 'TER' | null
  pns_grade?: string | null
  role?: Role | null
  is_active?: boolean
}

export type UpdatePegawaiData = Partial<CreatePegawaiData>
