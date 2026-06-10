-- ============================================
-- PINTAR-JP: Enterprise Incentive & KPI System
-- Database Schema for RSUD BENDAN
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- MASTER DATA TABLES
-- ============================================

-- Master Units (Organizational Units)
CREATE TABLE IF NOT EXISTS public.m_units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  proportion_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (proportion_percentage >= 0 AND proportion_percentage <= 100),
  remuneration_style VARCHAR(50) DEFAULT 'score_based' CHECK (remuneration_style IN ('score_based', 'activity_based_pir')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master Employees (Core employee data)
CREATE TABLE IF NOT EXISTS public.m_employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  employee_code VARCHAR(50) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  unit_id UUID NOT NULL REFERENCES m_units(id) ON DELETE RESTRICT,
  role VARCHAR(50) CHECK (role IN ('superadmin', 'unit_manager', 'employee')),
  email VARCHAR(255) UNIQUE NOT NULL,
  tax_status VARCHAR(10) DEFAULT 'TK/0' CHECK (tax_status IN ('TK/0', 'TK/1', 'TK/2', 'TK/3', 'K/0', 'K/1', 'K/2', 'K/3')),
  employment_status VARCHAR(50) CHECK (employment_status IN ('PNS', 'PPPK', 'PPPK PARUH WAKTU', 'BLUD')),
  employee_status VARCHAR(50) DEFAULT 'active',
  tax_type VARCHAR(20) DEFAULT 'Final',
  pns_grade VARCHAR(20),
  position VARCHAR(255),
  phone VARCHAR(50),
  nik VARCHAR(16),
  bank_name VARCHAR(100),
  bank_account_number VARCHAR(100),
  bank_account_name VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master KPI Categories
CREATE TABLE IF NOT EXISTS public.m_kpi_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID NOT NULL REFERENCES m_units(id) ON DELETE CASCADE,
  category VARCHAR(10) NOT NULL CHECK (category IN ('P1', 'P2', 'P3')),
  category_name VARCHAR(255) NOT NULL,
  weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (weight_percentage >= 0 AND weight_percentage <= 100),
  configuration_style VARCHAR(20) DEFAULT 'percentage' CHECK (configuration_style IN ('percentage', 'activity')),
  is_weighted BOOLEAN DEFAULT true,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(unit_id, category)
);

-- Master KPI Indicators
CREATE TABLE IF NOT EXISTS public.m_kpi_indicators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID NOT NULL REFERENCES m_kpi_categories(id) ON DELETE CASCADE,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  target_value DECIMAL(15,2) DEFAULT 100.00,
  weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (weight_percentage >= 0 AND weight_percentage <= 100),
  measurement_unit VARCHAR(50),
  calculation_method TEXT DEFAULT 'indexing' CHECK (calculation_method IN ('indexing', 'priority')),
  measurement_type TEXT DEFAULT 'scoring',
  unit_tariff DECIMAL(18,2) DEFAULT 0,
  base_index_value DECIMAL(18,2) DEFAULT 0,
  service_types TEXT[] DEFAULT '{}',
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(category_id, code)
);

-- Master KPI Sub-Indicators
CREATE TABLE IF NOT EXISTS public.m_kpi_sub_indicators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  indicator_id UUID NOT NULL REFERENCES m_kpi_indicators(id) ON DELETE CASCADE,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  target_value DECIMAL(15,2) DEFAULT 100.00,
  weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (weight_percentage >= 0 AND weight_percentage <= 100),
  measurement_unit VARCHAR(50),
  measurement_type TEXT DEFAULT 'scoring' CHECK (measurement_type IN ('scoring', 'quantitative')),
  scoring_criteria JSONB DEFAULT '[]'::jsonb,
  unit_tariff DECIMAL(18,2) DEFAULT 0,
  base_index_value DECIMAL(18,2) DEFAULT 0,
  service_types TEXT[] DEFAULT '{}',
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(indicator_id, code)
);

-- Master Tariffs
CREATE TABLE IF NOT EXISTS public.m_master_tariffs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  service_type TEXT,
  amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  type TEXT CHECK (type IN ('index', 'activity')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRANSACTION TABLES
-- ============================================

-- Pool Dana
CREATE TABLE IF NOT EXISTS public.t_pool (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  period VARCHAR(7) NOT NULL,
  revenue_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  deduction_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  net_pool DECIMAL(18,2) GENERATED ALWAYS AS (revenue_total - deduction_total) STORED,
  global_allocation_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.00,
  allocated_amount DECIMAL(18,2) GENERATED ALWAYS AS ((revenue_total - deduction_total) * global_allocation_percentage / 100) STORED,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'distributed')),
  approved_by UUID REFERENCES public.m_employees(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(period)
);

-- Pool Revenue Details
CREATE TABLE IF NOT EXISTS public.t_pool_revenue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID NOT NULL REFERENCES public.t_pool(id) ON DELETE CASCADE,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pool Deduction Details
CREATE TABLE IF NOT EXISTS public.t_pool_deduction (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID NOT NULL REFERENCES public.t_pool(id) ON DELETE CASCADE,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KPI Realization (Input data)
CREATE TABLE IF NOT EXISTS public.t_realization (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.m_employees(id) ON DELETE CASCADE,
  indicator_id UUID NOT NULL REFERENCES public.m_kpi_indicators(id) ON DELETE CASCADE,
  sub_indicator_id UUID REFERENCES public.m_kpi_sub_indicators(id),
  period VARCHAR(7) NOT NULL,
  realization_value DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  achievement_percentage DECIMAL(5,2),
  score DECIMAL(10,2),
  notes TEXT,
  created_by UUID REFERENCES public.m_employees(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, indicator_id, sub_indicator_id, period)
);

-- KPI Assessments
CREATE TABLE IF NOT EXISTS public.t_kpi_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.m_employees(id) ON DELETE CASCADE,
  indicator_id UUID NOT NULL REFERENCES public.m_kpi_indicators(id) ON DELETE CASCADE,
  sub_indicator_id UUID REFERENCES public.m_kpi_sub_indicators(id),
  period VARCHAR(7) NOT NULL,
  realization_value DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  target_value DECIMAL(15,2) NOT NULL,
  weight_percentage DECIMAL(5,2) NOT NULL,
  achievement_percentage DECIMAL(5,2) DEFAULT 0.00,
  score DECIMAL(10,2) DEFAULT 0.00,
  notes TEXT,
  assessor_id UUID NOT NULL REFERENCES public.m_employees(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, indicator_id, sub_indicator_id, period)
);

-- Unit Scores
CREATE TABLE IF NOT EXISTS public.t_unit_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID NOT NULL REFERENCES public.m_units(id) ON DELETE CASCADE,
  period VARCHAR(7) NOT NULL,
  score DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(unit_id, period)
);

-- Individual Scores
CREATE TABLE IF NOT EXISTS public.t_individual_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.m_employees(id) ON DELETE CASCADE,
  period VARCHAR(7) NOT NULL,
  score DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, period)
);

-- Calculation Results
CREATE TABLE IF NOT EXISTS public.t_calculation_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.m_employees(id) ON DELETE CASCADE,
  period VARCHAR(7) NOT NULL,
  pool_id UUID NOT NULL REFERENCES public.t_pool(id) ON DELETE CASCADE,
  unit_score DECIMAL(10,2) DEFAULT 0.00,
  individual_score DECIMAL(10,2) DEFAULT 0.00,
  final_score DECIMAL(10,2) DEFAULT 0.00,
  unit_allocated_amount DECIMAL(18,2) DEFAULT 0.00,
  score_proportion DECIMAL(15,10) DEFAULT 0.00,
  gross_incentive DECIMAL(18,2) DEFAULT 0.00,
  tax_amount DECIMAL(18,2) DEFAULT 0.00,
  net_incentive DECIMAL(18,2) DEFAULT 0.00,
  activity_based_incentive DECIMAL(18,2) DEFAULT 0.00,
  index_based_incentive DECIMAL(18,2) DEFAULT 0.00,
  calculation_metadata JSONB,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, period)
);


-- History PIR
CREATE TABLE IF NOT EXISTS public.t_history_pir (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  period VARCHAR(7) NOT NULL,
  unit_id UUID REFERENCES public.m_units(id),
  unit_name VARCHAR(255),
  net_pool_amount DECIMAL(18,2),
  proportion_percentage DECIMAL(10,4),
  allocated_for_unit DECIMAL(18,2),
  total_skor_kolektif DECIMAL(18,2),
  pir_value DECIMAL(18,6),
  employee_count INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SETTINGS AND SYSTEM TOOLS
-- ============================================

-- Settings
CREATE TABLE IF NOT EXISTS public.t_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  created_by UUID REFERENCES public.m_employees(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Log
CREATE TABLE IF NOT EXISTS public.t_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  user_name TEXT,
  table_name TEXT NOT NULL,
  operation VARCHAR(20) NOT NULL,
  record_id TEXT,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  details TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Auth Log
CREATE TABLE IF NOT EXISTS public.t_auth_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  action VARCHAR(50) NOT NULL,
  ip_address TEXT,
  success BOOLEAN DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.t_notification (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.m_employees(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'general',
  read BOOLEAN DEFAULT false,
  link TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VIEWS
-- ============================================

-- Assessment Status View
CREATE OR REPLACE VIEW public.v_assessment_status AS
SELECT 
  e.id as employee_id,
  e.full_name,
  e.unit_id,
  u.name as unit_name,
  p.period,
  COUNT(i.id) as total_indicators,
  COUNT(a.id) as assessed_indicators,
  CASE 
    WHEN COUNT(a.id) = 0 THEN 'Belum Dinilai'
    WHEN COUNT(a.id) = COUNT(i.id) THEN 'Selesai'
    ELSE 'Sebagian'
  END as status,
  ROUND((COUNT(a.id)::decimal / NULLIF(COUNT(i.id), 0) * 100), 2) as completion_percentage
FROM public.m_employees e
JOIN public.m_units u ON e.unit_id = u.id
CROSS JOIN (
  SELECT DISTINCT period 
  FROM public.t_pool 
) p
LEFT JOIN public.m_kpi_categories c ON c.unit_id = e.unit_id AND c.is_active = true
LEFT JOIN public.m_kpi_indicators i ON i.category_id = c.id AND i.is_active = true
LEFT JOIN public.t_kpi_assessments a ON a.employee_id = e.id 
  AND a.indicator_id = i.id 
  AND a.period = p.period
WHERE e.is_active = true
GROUP BY e.id, e.full_name, e.unit_id, u.name, p.period;

-- ============================================
-- RLS CONFIGURATION
-- ============================================

ALTER TABLE public.m_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.m_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.m_kpi_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.m_kpi_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.m_kpi_sub_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_pool ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_realization ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_kpi_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_calculation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.t_notification ENABLE ROW LEVEL SECURITY;

-- ... (RLS Policies would follow)