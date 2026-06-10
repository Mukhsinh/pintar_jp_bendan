import { createClient } from '@/lib/supabase/client'
import { type Role, type UserWithEmployee, type CreateUserInput, type UpdateUserInput } from '@/lib/types/database.types'

/**
 * Interface for simplified employee data
 */
export interface Employee {
  id: string
  user_id: string | null
  employee_code: string
  full_name: string
  email?: string | null
  unit_id: string
  role: Role
  tax_status?: string | null
  is_active: boolean
  created_at: string
  updated_at: string
  m_units?: {
    name: string
  }
}

/**
 * Generate a random 8-character alphanumeric password
 */
export function generateTemporaryPassword(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let password = ''
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return password
}


/**
 * Validate email format
 */
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

/**
 * Get all employees with pagination and search
 * Note: Does not include email/role - use server actions for that
 */
export async function getEmployees(
  page: number = 1,
  pageSize: number = 50,
  searchTerm: string = ''
): Promise<{ data: Employee[]; count: number; error?: string }> {
  try {
    const supabase = createClient()

    let query = supabase
      .from('m_employees')
      .select('id, user_id, employee_code, full_name, unit_id, tax_status, is_active, created_at, updated_at, m_units(name)', { count: 'exact' })
      .order('created_at', { ascending: false })

    if (searchTerm) {
      query = query.or(`full_name.ilike.%${searchTerm}%,employee_code.ilike.%${searchTerm}%`)
    }

    const from = (page - 1) * pageSize
    const to = from + pageSize - 1
    query = query.range(from, to)

    const { data, error, count } = await query

    if (error) {
      return { data: [], count: 0, error: error.message }
    }

    const transformedData: Employee[] = (data || []).map((item: any) => ({
      id: item.id,
      user_id: item.user_id,
      employee_code: item.employee_code,
      full_name: item.full_name,
      unit_id: item.unit_id,
      tax_status: item.tax_status,
      is_active: item.is_active,
      created_at: item.created_at,
      updated_at: item.updated_at,
      role: (item.role as Role) || 'employee',
      m_units: Array.isArray(item.m_units) && item.m_units.length > 0
        ? item.m_units[0]
        : undefined
    }))

    return { data: transformedData, count: count || 0 }
  } catch (err: any) {
    return { data: [], count: 0, error: err.message }
  }
}

/**
 * These are placeholders for client-side use. 
 * Actual implementation must be in server actions.
 */

export async function createUser(
  input: CreateUserInput
): Promise<{ success: boolean; user?: UserWithEmployee; error?: string; password?: string }> {
  console.error('createUser must be called via Server Action')
  return { success: false, error: 'Operation not permitted on client' }
}

export async function updateUser(
  userId: string,
  updates: UpdateUserInput
): Promise<{ success: boolean; error?: string }> {
  console.error('updateUser must be called via Server Action')
  return { success: false, error: 'Operation not permitted on client' }
}

export async function deactivateUser(
  userId: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = createClient()
    const { error } = await supabase
      .from('m_employees')
      .update({ is_active: false })
      .eq('user_id', userId)

    if (error) return { success: false, error: error.message }
    return { success: true }
  } catch (err: any) {
    return { success: false, error: err.message }
  }
}

export async function deleteEmployee(
  id: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const supabase = createClient()
    const { error } = await supabase
      .from('m_employees')
      .delete()
      .eq('id', id)

    if (error) return { success: false, error: error.message }
    return { success: true }
  } catch (err: any) {
    return { success: false, error: err.message }
  }
}
