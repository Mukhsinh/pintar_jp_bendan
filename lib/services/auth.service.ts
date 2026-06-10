import { createClient } from '@/lib/supabase/client'
import type { Session } from '@supabase/supabase-js'
import { handleAuthError, logAuthError } from '@/lib/utils/auth-errors'
import { type Role, type UserWithEmployee, type UserMetadata } from '@/lib/types/database.types'
import { clearAllStorage } from '@/lib/utils/storage-adapter'

export interface LoginCredentials {
  email: string
  password: string
}

export interface UserData {
  id: string
  email: string
  role: Role
  unit_id: string | null
  is_active: boolean
  full_name: string
}

export interface LoginResult {
  success: boolean
  user?: UserData
  error?: string
}

class AuthService {
  async signIn(email: string, password: string): Promise<LoginResult> {
    try {
      // Skip if running on server
      if (typeof window === 'undefined') {
        return {
          success: false,
          error: 'Login hanya dapat dilakukan di browser',
        }
      }

      const supabase = createClient()

      console.log('[AUTH] Starting sign in for:', email)

      // Clear any existing session first
      try {
        await supabase.auth.signOut({ scope: 'local' })
      } catch (clearError) {
        console.warn('[AUTH] Error clearing session:', clearError)
      }

      // Add timeout to prevent hanging
      const signInPromise = supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password: password,
      })

      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Login timeout')), 10000)
      )

      const { data: authData, error: authError } = await Promise.race([signInPromise, timeoutPromise]) as any

      if (authError || !authData.user) {
        console.error('[AUTH] Sign in failed:', authError)
        logAuthError('signIn', authError)
        return {
          success: false,
          error: handleAuthError(authError),
        }
      }

      console.log('[AUTH] Sign in successful, user ID:', authData.user.id)
      console.log('[AUTH] Fetching employee data...')

      // Fetch employee data first - this contains the role and other info
      const { data: employeeData, error: employeeError } = await supabase
        .from('m_employees')
        .select('id, full_name, unit_id, is_active, role')
        .eq('user_id', authData.user.id)
        .single()

      if (employeeError) {
        console.error('[AUTH] Employee fetch error:', employeeError)
        logAuthError('employee-fetch', employeeError)
        await supabase.auth.signOut()
        return {
          success: false,
          error: 'Gagal mengambil data pegawai',
        }
      }

      const role = (employeeData?.role as Role) || (authData.user.user_metadata?.role as Role)

      if (!role) {
        console.error('[AUTH] Role not found in employee data or metadata')
        logAuthError('user-fetch', new Error('Role not found'))
        await supabase.auth.signOut()
        return {
          success: false,
          error: 'Data pengguna tidak ditemukan',
        }
      }

      if (!employeeData?.is_active) {
        console.warn('[AUTH] Employee is inactive')
        await supabase.auth.signOut()
        return {
          success: false,
          error: 'Akun Anda tidak aktif',
        }
      }

      const userDataResult: UserData = {
        id: authData.user.id,
        email: authData.user.email || '',
        role: role,
        unit_id: employeeData.unit_id,
        is_active: employeeData.is_active,
        full_name: employeeData.full_name,
      }

      return {
        success: true,
        user: userDataResult
      }
    } catch (error: any) {
      console.error('[AUTH] Exception during sign in:', error)
      return {
        success: false,
        error: 'Terjadi kesalahan, silakan coba lagi',
      }
    }
  }

  async login(credentials: LoginCredentials): Promise<LoginResult> {
    return this.signIn(credentials.email, credentials.password)
  }

  async signOut(): Promise<void> {
    try {
      const supabase = createClient()
      await supabase.auth.signOut({ scope: 'global' })

      if (typeof window !== 'undefined') {
        clearAllStorage()
        window.location.replace('/login')
      }
    } catch (error) {
      console.error('[AUTH] Exception during sign out:', error)
      if (typeof window !== 'undefined') {
        clearAllStorage()
        window.location.replace('/login')
      }
    }
  }

  async logout(): Promise<void> {
    const { handleLogout } = await import('@/lib/utils/logout-handler')
    await handleLogout()
  }

  async getCurrentUser(): Promise<UserData | null> {
    try {
      const supabase = createClient()
      const { data: { session } } = await supabase.auth.getSession()

      if (!session) return null

      const { data: employeeData, error } = await supabase
        .from('m_employees')
        .select('id, full_name, unit_id, is_active, role')
        .eq('user_id', session.user.id)
        .single()

      if (error || !employeeData) return null

      const role = (employeeData.role as Role) || (session.user.user_metadata?.role as Role)
      if (!role) return null

      return {
        id: session.user.id,
        email: session.user.email || '',
        role: role,
        unit_id: employeeData.unit_id,
        is_active: employeeData.is_active,
        full_name: employeeData.full_name,
      }
    } catch (error) {
      return null
    }
  }

  async isAuthenticated(): Promise<boolean> {
    try {
      const supabase = createClient()
      const { data: { session } } = await supabase.auth.getSession()
      return !!session
    } catch (error) {
      return false
    }
  }

  async getCurrentUserWithEmployee(): Promise<UserWithEmployee | null> {
    try {
      const supabase = createClient()
      const { data: { session } } = await supabase.auth.getSession()

      if (!session) return null

      const { data: employeeData, error: employeeError } = await supabase
        .from('m_employees')
        .select('id, employee_code, full_name, unit_id, tax_status, is_active, role, created_at, updated_at')
        .eq('user_id', session.user.id)
        .single()

      if (employeeError || !employeeData) return null

      const role = (employeeData.role as Role) || (session.user.user_metadata?.role as Role)
      if (!role) return null

      return {
        id: session.user.id,
        email: session.user.email || '',
        role: role,
        employeeId: employeeData.id,
        employeeCode: employeeData.employee_code,
        fullName: employeeData.full_name,
        unitId: employeeData.unit_id,
        taxStatus: employeeData.tax_status,
        isActive: employeeData.is_active,
        createdAt: employeeData.created_at,
        updatedAt: employeeData.updated_at,
        employee: employeeData as any
      }
    } catch (error) {
      return null
    }
  }
}

export const authService = new AuthService()
