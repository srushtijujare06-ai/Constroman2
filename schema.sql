-- PostgreSQL schema aligned to the DPR workbook structure.
-- This keeps the core multi-tenant/project/report model and adds
-- register + field-definition tables so the Excel formats are
-- represented explicitly in SQL.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  domain VARCHAR(255),
  password_hash TEXT,
  logo_url VARCHAR(500),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_organizations_is_active
  ON organizations (is_active);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  role_id INTEGER REFERENCES roles(id),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'employee',
  phone VARCHAR(50),
  avatar_url VARCHAR(500),
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT uq_users_org_email UNIQUE (organization_id, email)
);

CREATE INDEX IF NOT EXISTS ix_users_org_id
  ON users (organization_id);

CREATE INDEX IF NOT EXISTS ix_users_role
  ON users (role);

CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50),
  description TEXT,
  location VARCHAR(255),
  start_date DATE,
  end_date DATE,
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  custom_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_projects_org_id
  ON projects (organization_id);

CREATE INDEX IF NOT EXISTS ix_projects_org_status
  ON projects (organization_id, status);

CREATE TABLE IF NOT EXISTS subprojects (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  start_date DATE,
  end_date DATE,
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  custom_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_subprojects_project_id
  ON subprojects (project_id);

CREATE INDEX IF NOT EXISTS ix_subprojects_project_status
  ON subprojects (project_id, status);

CREATE TABLE IF NOT EXISTS project_assignments (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assignment_role VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_project_assignments_project_user UNIQUE (project_id, user_id)
);

CREATE INDEX IF NOT EXISTS ix_project_assignments_project_id
  ON project_assignments (project_id);

CREATE INDEX IF NOT EXISTS ix_project_assignments_user_id
  ON project_assignments (user_id);

CREATE TABLE IF NOT EXISTS reports (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  subproject_id INTEGER REFERENCES subprojects(id) ON DELETE SET NULL,
  report_date DATE NOT NULL,
  title VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  weather JSONB,
  prepared_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  approved_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT uq_reports_project_subproject_date UNIQUE (project_id, subproject_id, report_date)
);

CREATE INDEX IF NOT EXISTS ix_reports_org_project_date
  ON reports (organization_id, project_id, report_date);

CREATE INDEX IF NOT EXISTS ix_reports_status
  ON reports (status);

CREATE TABLE IF NOT EXISTS registers (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
  workbook_sheet_name VARCHAR(255),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(100),
  scope VARCHAR(20) NOT NULL DEFAULT 'project',
  sort_order INTEGER NOT NULL DEFAULT 0,
  allow_multiple_per_day BOOLEAN NOT NULL DEFAULT TRUE,
  enable_serial_number BOOLEAN NOT NULL DEFAULT FALSE,
  serial_prefix VARCHAR(50),
  serial_format VARCHAR(100),
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT uq_registers_org_slug UNIQUE (organization_id, slug)
);

CREATE INDEX IF NOT EXISTS ix_registers_org_active
  ON registers (organization_id, is_active);

CREATE INDEX IF NOT EXISTS ix_registers_sort_order
  ON registers (sort_order);

CREATE UNIQUE INDEX IF NOT EXISTS uq_registers_global_slug
  ON registers (slug)
  WHERE organization_id IS NULL;

CREATE TABLE IF NOT EXISTS register_fields (
  id SERIAL PRIMARY KEY,
  register_id INTEGER NOT NULL REFERENCES registers(id) ON DELETE CASCADE,
  section_name VARCHAR(255),
  field_key VARCHAR(255) NOT NULL,
  field_label VARCHAR(255) NOT NULL,
  field_type VARCHAR(50) NOT NULL DEFAULT 'text',
  data_type VARCHAR(50) NOT NULL DEFAULT 'string',
  column_order INTEGER NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT FALSE,
  is_repeatable BOOLEAN NOT NULL DEFAULT FALSE,
  is_header BOOLEAN NOT NULL DEFAULT FALSE,
  default_value TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_register_fields_register_key UNIQUE (register_id, field_key)
);

CREATE INDEX IF NOT EXISTS ix_register_fields_register_order
  ON register_fields (register_id, column_order);

CREATE TABLE IF NOT EXISTS form_templates (
  id SERIAL PRIMARY KEY,
  register_id INTEGER NOT NULL REFERENCES registers(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  version INTEGER NOT NULL,
  schema_json JSONB NOT NULL,
  ui_schema JSONB,
  validation_rules JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ,
  created_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT uq_form_templates_register_version UNIQUE (register_id, version)
);

CREATE INDEX IF NOT EXISTS ix_form_templates_register_state
  ON form_templates (register_id, is_active, is_published);

CREATE TABLE IF NOT EXISTS submissions (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
  subproject_id INTEGER REFERENCES subprojects(id) ON DELETE SET NULL,
  register_id INTEGER NOT NULL REFERENCES registers(id) ON DELETE CASCADE,
  template_id INTEGER REFERENCES form_templates(id) ON DELETE SET NULL,
  report_id INTEGER REFERENCES reports(id) ON DELETE SET NULL,
  submission_date DATE NOT NULL DEFAULT CURRENT_DATE,
  title VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'draft',
  serial_no INTEGER,
  form_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  custom_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  submitted_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  submitted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_submissions_org_register_date
  ON submissions (organization_id, register_id, submission_date);

CREATE INDEX IF NOT EXISTS ix_submissions_org_register_status
  ON submissions (organization_id, register_id, status);

CREATE INDEX IF NOT EXISTS ix_submissions_project_register
  ON submissions (project_id, register_id);

CREATE INDEX IF NOT EXISTS ix_submissions_form_data_gin
  ON submissions USING GIN (form_data);

CREATE TABLE IF NOT EXISTS submission_rows (
  id SERIAL PRIMARY KEY,
  submission_id INTEGER NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  section_name VARCHAR(255),
  row_index INTEGER NOT NULL DEFAULT 1,
  row_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_submission_rows_submission_section_row UNIQUE (submission_id, section_name, row_index)
);

CREATE INDEX IF NOT EXISTS ix_submission_rows_submission_id
  ON submission_rows (submission_id);

CREATE TABLE IF NOT EXISTS remarks (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  report_id INTEGER REFERENCES reports(id) ON DELETE CASCADE,
  submission_id INTEGER REFERENCES submissions(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  remark_scope VARCHAR(50) NOT NULL DEFAULT 'general',
  remark_text TEXT NOT NULL,
  is_admin_only BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS attachments (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  submission_id INTEGER REFERENCES submissions(id) ON DELETE CASCADE,
  report_id INTEGER REFERENCES reports(id) ON DELETE CASCADE,
  file_name VARCHAR(500) NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  storage_path VARCHAR(1000) NOT NULL,
  storage_provider VARCHAR(50) NOT NULL DEFAULT 'local',
  uploaded_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS approval_workflows (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  register_id INTEGER NOT NULL REFERENCES registers(id) ON DELETE CASCADE,
  steps JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT uq_approval_workflows_register UNIQUE (register_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  link VARCHAR(500),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_notifications_user_unread
  ON notifications (user_id, is_read, created_at);

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGSERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INTEGER NOT NULL,
  action VARCHAR(50) NOT NULL,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  changes JSONB,
  context JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_audit_logs_entity
  ON audit_logs (entity_type, entity_id, created_at);

CREATE INDEX IF NOT EXISTS ix_audit_logs_org_type
  ON audit_logs (organization_id, entity_type, created_at);

INSERT INTO roles (code, name, description)
VALUES
  ('admin', 'Admin', 'Organization administrator'),
  ('employee', 'Employee', 'Project employee')
ON CONFLICT (code) DO NOTHING;

INSERT INTO registers (
  organization_id,
  workbook_sheet_name,
  name,
  slug,
  description,
  scope,
  sort_order,
  allow_multiple_per_day,
  enable_serial_number,
  serial_prefix,
  serial_format,
  is_system,
  config
)
VALUES
  (NULL, '00. Site Report', 'Site Report', 'site-report', 'Daily site report header with labour, material, RMC and reinforcement summary.', 'project', 1, FALSE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"00. Site Report"}'::jsonb),
  (NULL, '1.01 Weather', 'Weather Log', 'weather-log', 'Daily temperature and rainfall observations.', 'project', 2, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"1.01 Weather"}'::jsonb),
  (NULL, '1.02 Site Diary', 'Site Diary', 'site-diary', 'Daily site diary entries.', 'project', 3, TRUE, TRUE, 'SD', 'SD-{year}-{serial}', TRUE, '{"excel_sheet":"1.02 Site Diary"}'::jsonb),
  (NULL, '1.03 Hindrance', 'Hindrance Register', 'hindrance-register', 'Hindrance logging and closure tracking.', 'project', 4, TRUE, TRUE, 'HR', 'HR-{year}-{serial}', TRUE, '{"excel_sheet":"1.03 Hindrance"}'::jsonb),
  (NULL, '2.01 Customer Milestones', 'Customer Milestones', 'customer-milestones', 'Customer milestone progress register.', 'project', 5, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"2.01 Customer Milestones"}'::jsonb),
  (NULL, '2.02 Construction Milestone', 'Construction Milestones', 'construction-milestones', 'Construction milestone progress register.', 'project', 6, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"2.02 Construction Milestone"}'::jsonb),
  (NULL, '2.03 Work & Labor', 'Work And Labour', 'work-labour', 'Work completion and labour details.', 'project', 7, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"2.03 Work & Labor"}'::jsonb),
  (NULL, '2.04 Dept. Lab Register', 'Departmental Labour Register', 'departmental-labour-register', 'Department labour attendance and recovery details.', 'project', 8, TRUE, TRUE, 'DL', 'DL-{year}-{serial}', TRUE, '{"excel_sheet":"2.04 Dept. Lab Register"}'::jsonb),
  (NULL, '3.01 Material Recpt', 'Material Receipt Register', 'material-receipt-register', 'Material inward receipt and rejection details.', 'project', 9, TRUE, TRUE, 'MR', 'MR-{year}-{serial}', TRUE, '{"excel_sheet":"3.01 Material Recpt"}'::jsonb),
  (NULL, 'Mat Issue Reg', 'Material Issue Register', 'material-issue-register', 'Material issue and return tracking.', 'project', 10, TRUE, TRUE, 'MI', 'MI-{year}-{serial}', TRUE, '{"excel_sheet":"Mat Issue Reg"}'::jsonb),
  (NULL, 'WaterTank', 'Water Tank Register', 'water-tank-register', 'Water tank register placeholder from workbook.', 'project', 11, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"WaterTank"}'::jsonb),
  (NULL, 'Ele Meter', 'Electric Meter Register', 'electric-meter-register', 'Electric meter register placeholder from workbook.', 'project', 12, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"Ele Meter"}'::jsonb),
  (NULL, 'DG Reg', 'DG Register', 'dg-register', 'DG register placeholder from workbook.', 'project', 13, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"DG Reg"}'::jsonb),
  (NULL, '03.Plan Board', 'Plan Board', 'plan-board', 'Plan board placeholder from workbook.', 'project', 14, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"03.Plan Board"}'::jsonb),
  (NULL, '04. Dwg Reg', 'Drawing Register', 'drawing-register', 'Drawing register.', 'project', 15, TRUE, TRUE, 'DWG', 'DWG-{year}-{serial}', TRUE, '{"excel_sheet":"04. Dwg Reg"}'::jsonb),
  (NULL, '05. RFI Reg', 'RFI Register', 'rfi-register', 'RFI tracking register.', 'project', 16, TRUE, TRUE, 'RFI', 'RFI-{year}-{serial}', TRUE, '{"excel_sheet":"05. RFI Reg"}'::jsonb),
  (NULL, 'RMC', 'RMC Register', 'rmc-register', 'RMC register placeholder from workbook.', 'project', 17, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"RMC"}'::jsonb),
  (NULL, 'Reinf', 'Reinforcement Register', 'reinforcement-register', 'Reinforcement register placeholder from workbook.', 'project', 18, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"Reinf"}'::jsonb),
  (NULL, 'CubeTest', 'Cube Test Register', 'cube-test-register', 'Cube test register placeholder from workbook.', 'project', 19, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"CubeTest"}'::jsonb),
  (NULL, 'Safety', 'Safety Register', 'safety-register', 'Safety register placeholder from workbook.', 'project', 20, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"Safety"}'::jsonb),
  (NULL, 'Accident', 'Accident Register', 'accident-register', 'Accident register placeholder from workbook.', 'project', 21, TRUE, FALSE, NULL, NULL, TRUE, '{"excel_sheet":"Accident"}'::jsonb),
  (NULL, 'Instruction Reg', 'Instruction Register', 'instruction-register', 'Instruction register placeholder from workbook.', 'project', 22, TRUE, TRUE, 'INS', 'INS-{year}-{serial}', TRUE, '{"excel_sheet":"Instruction Reg"}'::jsonb),
  (NULL, 'Petty Cash', 'Petty Cash Register', 'petty-cash-register', 'Petty cash expenses register.', 'project', 23, TRUE, TRUE, 'PC', 'PC-{year}-{serial}', TRUE, '{"excel_sheet":"Petty Cash"}'::jsonb),
  (NULL, 'QC', 'Quality Non Conformity Register', 'quality-nc-register', 'Quality non conformity register.', 'project', 24, TRUE, TRUE, 'QNC', 'QNC-{year}-{serial}', TRUE, '{"excel_sheet":"QC"}'::jsonb),
  (NULL, 'WO Register', 'Work Order Register', 'work-order-register', 'Work order register.', 'project', 25, TRUE, TRUE, 'WO', 'WO-{year}-{serial}', TRUE, '{"excel_sheet":"WO Register"}'::jsonb),
  (NULL, 'WO Rev', 'Work Order Revision Register', 'work-order-revision-register', 'Work order revision register.', 'project', 26, TRUE, TRUE, 'WOR', 'WOR-{year}-{serial}', TRUE, '{"excel_sheet":"WO Rev"}'::jsonb),
  (NULL, 'Invoice Register', 'Invoice Register', 'invoice-register', 'Contractor invoice register.', 'project', 27, TRUE, TRUE, 'INV', 'INV-{year}-{serial}', TRUE, '{"excel_sheet":"Invoice Register"}'::jsonb),
  (NULL, 'Debit Note Reg', 'Debit Note Register', 'debit-note-register', 'Debit note register.', 'project', 28, TRUE, TRUE, 'DN', 'DN-{year}-{serial}', TRUE, '{"excel_sheet":"Debit Note Reg"}'::jsonb),
  (NULL, 'PR Reg', 'Purchase Requisition Register', 'purchase-requisition-register', 'Purchase requisition register.', 'project', 29, TRUE, TRUE, 'PR', 'PR-{year}-{serial}', TRUE, '{"excel_sheet":"PR Reg"}'::jsonb),
  (NULL, 'PO Reg', 'Purchase Order Register', 'purchase-order-register', 'Purchase order register.', 'project', 30, TRUE, TRUE, 'PO', 'PO-{year}-{serial}', TRUE, '{"excel_sheet":"PO Reg"}'::jsonb),
  (NULL, 'Inv Reg', 'Inventory Invoice Register', 'inventory-invoice-register', 'Vendor invoice register.', 'project', 31, TRUE, TRUE, 'VINV', 'VINV-{year}-{serial}', TRUE, '{"excel_sheet":"Inv Reg"}'::jsonb)
ON CONFLICT DO NOTHING;

WITH field_seed(register_slug, section_name, field_key, field_label, field_type, data_type, column_order, is_required, is_repeatable, is_header) AS (
  VALUES
    ('site-report', 'header', 'project_name', 'Project', 'text', 'string', 1, TRUE, FALSE, FALSE),
    ('site-report', 'header', 'report_date', 'Date', 'date', 'date', 2, TRUE, FALSE, FALSE),
    ('site-report', 'header', 'rain_from', 'Rain From', 'time', 'time', 3, FALSE, FALSE, FALSE),
    ('site-report', 'header', 'rain_to', 'Rain To', 'time', 'time', 4, FALSE, FALSE, FALSE),
    ('site-report', 'work_labour', 'item_no', 'Item No.', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'description', 'Description', 'textarea', 'string', 6, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'carpenter', 'Carpenter', 'number', 'integer', 7, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'fitter', 'Fitter', 'number', 'integer', 8, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'helper', 'Helper', 'number', 'integer', 9, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'mason', 'Mason', 'number', 'integer', 10, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'skilled', 'Skilled', 'number', 'integer', 11, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'unskilled', 'Unskilled', 'number', 'integer', 12, FALSE, TRUE, FALSE),
    ('site-report', 'work_labour', 'total_labour', 'Total', 'number', 'integer', 13, FALSE, TRUE, FALSE),
    ('site-report', 'summary', 'todays_total_strength', 'Today''s Total Strength', 'number', 'integer', 14, FALSE, FALSE, FALSE),
    ('site-report', 'summary', 'remarks', 'Remarks (Shortfall of Labors/ Materials, if Any)', 'textarea', 'string', 15, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_previous_receipt', 'RMC Previous Receipt', 'number', 'decimal', 16, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_today_receipt', 'RMC Today''s Receipt', 'number', 'decimal', 17, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_cumulative_receipt', 'RMC Cumulative Receipt', 'number', 'decimal', 18, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_opening_balance', 'RMC Opening Balance', 'number', 'decimal', 19, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_today_consumption', 'RMC Today''s Consumption', 'number', 'decimal', 20, FALSE, FALSE, FALSE),
    ('site-report', 'rmc', 'rmc_closing_balance', 'RMC Closing Balance', 'number', 'decimal', 21, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_previous_receipt', 'Reinforcement Previous Receipt', 'number', 'decimal', 22, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_today_receipt', 'Reinforcement Today''s Receipt', 'number', 'decimal', 23, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_cumulative_receipt', 'Reinforcement Cumulative Receipt', 'number', 'decimal', 24, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_opening_balance', 'Reinforcement Opening Balance', 'number', 'decimal', 25, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_today_consumption', 'Reinforcement Today''s Consumption', 'number', 'decimal', 26, FALSE, FALSE, FALSE),
    ('site-report', 'reinforcement', 'reinf_closing_balance', 'Reinforcement Closing Balance', 'number', 'decimal', 27, FALSE, FALSE, FALSE),
    ('weather-log', 'main', 'report_date', 'Date', 'date', 'date', 1, TRUE, FALSE, FALSE),
    ('weather-log', 'main', 'temp_12pm', 'Temp @ 12PM', 'number', 'decimal', 2, FALSE, FALSE, FALSE),
    ('weather-log', 'main', 'rain_start', 'Rain Start', 'time', 'time', 3, FALSE, FALSE, FALSE),
    ('weather-log', 'main', 'rain_end', 'Rain Start2', 'time', 'time', 4, FALSE, FALSE, FALSE),
    ('weather-log', 'main', 'remarks', 'Remarks', 'textarea', 'string', 5, FALSE, FALSE, FALSE),
    ('site-diary', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('site-diary', 'main', 'entry_date', 'Date', 'date', 'date', 2, TRUE, TRUE, FALSE),
    ('site-diary', 'main', 'details', 'Details', 'textarea', 'string', 3, TRUE, TRUE, FALSE),
    ('site-diary', 'main', 'remarks', 'Remarks', 'textarea', 'string', 4, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'entry_date', 'Date', 'date', 'date', 2, TRUE, TRUE, FALSE),
    ('hindrance-register', 'main', 'hindrance_details', 'Details of Hindrance', 'textarea', 'string', 3, TRUE, TRUE, FALSE),
    ('hindrance-register', 'main', 'affected_work_items', 'Items of work that are affected due to the Hindrance', 'textarea', 'string', 4, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'recording_date', 'Date of Recording', 'date', 'date', 5, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'start_date', 'Start Date of Hindrance', 'date', 'date', 6, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'closure_date', 'Date of Closure of Hindrance', 'date', 'date', 7, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'total_hindrance_period', 'Total Period of Hindrance', 'number', 'decimal', 8, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'overlapping_period', 'Overlapping Period/ Float, if any', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'net_hindrance_days', 'Net hindrance days', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'approved_by', 'Approved by', 'text', 'string', 11, FALSE, TRUE, FALSE),
    ('hindrance-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 12, FALSE, TRUE, FALSE),
    ('customer-milestones', 'main', 'report_date', 'Date', 'date', 'date', 1, TRUE, FALSE, FALSE),
    ('customer-milestones', 'main', 'customer_milestone', 'Customer Milestone', 'text', 'string', 2, TRUE, TRUE, FALSE),
    ('customer-milestones', 'main', 'activity', 'Activity', 'text', 'string', 3, TRUE, TRUE, FALSE),
    ('customer-milestones', 'main', 'work_completed_today', 'Work Completed Today (%age)', 'number', 'decimal', 4, FALSE, TRUE, FALSE),
    ('customer-milestones', 'main', 'contractor', 'Contractor', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('construction-milestones', 'main', 'report_date', 'Date', 'date', 'date', 1, TRUE, FALSE, FALSE),
    ('construction-milestones', 'main', 'construction_milestone', 'Construction Milestone', 'text', 'string', 2, TRUE, TRUE, FALSE),
    ('construction-milestones', 'main', 'activity', 'Activity', 'text', 'string', 3, TRUE, TRUE, FALSE),
    ('construction-milestones', 'main', 'work_completed_today', 'Work Completed Today (%age)', 'number', 'decimal', 4, FALSE, TRUE, FALSE),
    ('construction-milestones', 'main', 'contractor', 'Contractor', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'report_date', 'Date', 'date', 'date', 1, TRUE, FALSE, FALSE),
    ('work-labour', 'main', 'milestone', 'Milestone', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'activity', 'Activity', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'work_completed', 'Work Completed', 'number', 'decimal', 4, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'unit', 'Unit', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'contractor', 'Contractor', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'category', 'Category', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'labour_count', 'No. of Labors', 'number', 'integer', 8, FALSE, TRUE, FALSE),
    ('work-labour', 'main', 'remarks', 'Remarks', 'textarea', 'string', 9, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'entry_date', 'Date', 'date', 'date', 2, TRUE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'challan_no', 'Challan No.', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'sub_contractor_name', 'Sub-Contractor''s Name', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'labour_name', 'Name of the Labor', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'labour_category', 'Labour Category', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'mandays', 'No. of Mandays', 'number', 'decimal', 7, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'workdone_details', 'Workdone Details', 'textarea', 'string', 8, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'approx_quantity', 'Approx. Quantity', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'unit', 'Unit', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'recovery_from', 'Recovery From', 'text', 'string', 11, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'recovery_rate', 'Recovery Rate', 'number', 'decimal', 12, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'recovery_amount', 'Recovery Amount', 'number', 'decimal', 13, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'authorised_by', 'Authorised by', 'text', 'string', 14, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'debit_details', 'Debit Details', 'textarea', 'string', 15, FALSE, TRUE, FALSE),
    ('departmental-labour-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 16, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'entry_date', 'Date', 'date', 'date', 2, TRUE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'time_in', 'Time in', 'time', 'time', 3, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'po_no', 'PO No.', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'grn_no', 'GRN No', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'material_description', 'Material Description', 'text', 'string', 6, TRUE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'unit', 'Unit', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'supplier', 'Supplier', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'quantity_received', 'Quantity Received', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'quantity_rejected', 'Quantity Rejected', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'quantity_accepted', 'Quantity Accepted', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('material-receipt-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 12, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'entry_date', 'Date', 'date', 'date', 2, TRUE, TRUE, FALSE),
    ('material-issue-register', 'main', 'entry_time', 'Time', 'time', 'time', 3, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'issue_slip_no', 'Issue Slip No', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'issue_slip_date', 'ISSUE Slip Date', 'date', 'date', 5, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'wo_no', 'WO No', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'contractor_name', 'CONTRACTOR NAME', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'grn_no', 'GRN No.', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'material_name', 'MATERIAL NAME', 'text', 'string', 9, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'unit', 'UNIT', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'qty_issued', 'QTY ISSUED', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'qty_returned', 'QTY Returned', 'number', 'decimal', 12, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'milestone_details', 'Milestone Details', 'text', 'string', 13, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'wbs_1', 'WBS 1', 'text', 'string', 14, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'wbs_2', 'WBS 2', 'text', 'string', 15, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'location', 'LOCATION', 'text', 'string', 16, FALSE, TRUE, FALSE),
    ('material-issue-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 17, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'sr_no', 'Sr.No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'building', 'Building', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'type', 'Type', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'particulars', 'Particulars', 'textarea', 'string', 4, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'required_date', 'Required Date', 'date', 'date', 5, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'drawing_no', 'DWG No.', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'drawing_date', 'DWG Date', 'date', 'date', 7, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'revision', 'Rev', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'revision_date', 'Rev Date', 'date', 'date', 9, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'received_date', 'Recd Date', 'date', 'date', 10, FALSE, TRUE, FALSE),
    ('drawing-register', 'main', 'status_remarks', 'Status/ Remarks', 'textarea', 'string', 11, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'rfi_no', 'RFI NO', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'consultant', 'Consultant', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'trade', 'Trade', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'rfi_date', 'RFI Date', 'date', 'date', 4, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'sent_by', 'Send By', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'drawing_reference', 'Drawing Reference', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'rfi_details', 'RFI Details', 'textarea', 'string', 7, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'references', 'References', 'textarea', 'string', 8, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'urgency', 'Urgency', 'text', 'string', 9, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'responsible', 'RESPONSIBLE', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'target_date', 'Target Date', 'date', 'date', 11, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'status', 'STATUS', 'text', 'string', 12, FALSE, TRUE, FALSE),
    ('rfi-register', 'main', 'remarks', 'REMARKS', 'textarea', 'string', 13, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'cost_head', 'Cost Head', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'entry_date', 'Date', 'date', 'date', 3, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'expense_details', 'Expenses Details', 'textarea', 'string', 4, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'amount_received', 'Amount Received', 'number', 'decimal', 5, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'paid_to', 'Paid to', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'amount_paid', 'Amount Paid', 'number', 'decimal', 7, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'debit_to', 'Debit to', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'debit_details', 'Debit Details', 'textarea', 'string', 9, FALSE, TRUE, FALSE),
    ('petty-cash-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 10, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'nc_no', 'NC No', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'entry_date', 'Date', 'date', 'date', 3, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'subcontractor_name', 'SubContractor''s Name', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'activity', 'Activity', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'nc_description', 'NC Description', 'textarea', 'string', 6, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'suggested_remedy', 'Suggested Remedy', 'textarea', 'string', 7, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'responsible_person', 'Responsible Person', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'closure_details', 'NC Closure Details', 'textarea', 'string', 9, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'closure_date', 'Closure Date', 'date', 'date', 10, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'closure_authorised_by', 'Closure Authorised by', 'text', 'string', 11, FALSE, TRUE, FALSE),
    ('quality-nc-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 12, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'cost_head', 'Cost Head', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'cost_head_detail_1', 'Cost Head Details 1', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'cost_head_detail_2', 'Cost Head Details 2', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'department', 'Dept', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'wo_no', 'WO No', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'entry_date', 'Date', 'date', 'date', 7, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'agency_name', 'Name of the Agency', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'quotation_ref_date', 'Quotation Ref & Date', 'text', 'string', 9, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'pan', 'PAN', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'gst_no', 'GST No.', 'text', 'string', 11, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'work_order_details', 'Work Order Details', 'textarea', 'string', 12, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'wo_value_excl_taxes', 'Work Order Value (Excl Taxes)', 'number', 'decimal', 13, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'gst_on_wo', 'GST on WO', 'number', 'decimal', 14, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'wo_value_incl_taxes', 'Work Order Value (Incl Taxes)', 'number', 'decimal', 15, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'allocated_budget', 'Allocated Budget', 'number', 'decimal', 16, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'budget_difference', 'Diff in Budget - WO Value', 'number', 'decimal', 17, FALSE, TRUE, FALSE),
    ('work-order-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 18, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'wo_no', 'WO No.', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'agency_name', 'Name of the Agency', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'revision_details', 'Revision Details', 'textarea', 'string', 4, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'revision_date', 'Revision Date', 'date', 'date', 5, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'previous_cost', 'Previous Cost', 'number', 'decimal', 6, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'gst_on_previous_cost', 'GST on Prev Cost', 'number', 'decimal', 7, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'additional_cost', 'Additional Cost', 'number', 'decimal', 8, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'gst_on_additional_cost', 'GST on Additional Cost', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'total_cost_to_date', 'Total Cost to Date', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'gst_total_cost_to_date', 'GST on Total Cost to Date', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('work-order-revision-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 12, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'contractor', 'Contractor', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'wo_no', 'WO No.', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'wo_revision_details', 'WO Rev Details', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'invoice_no', 'Invoice No.', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'invoice_date', 'Invoice Date', 'date', 'date', 6, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'invoice_status', 'Invoice Status', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'gross_claimed_amount', 'Gross Claimed Amount', 'number', 'decimal', 8, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'gross_certified_amount', 'Gross Certified Amount', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'gst', 'GST', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'retention', 'Retention', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'debits', 'Debits', 'number', 'decimal', 12, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'tds', 'TDS', 'number', 'decimal', 13, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'net_payable', 'Net Payable', 'number', 'decimal', 14, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'payment_due_on', 'Payment Due on', 'date', 'date', 15, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'payment_method', 'Payment Method', 'text', 'string', 16, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'payment_instrument_details', 'Payment Instrument Details', 'text', 'string', 17, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'net_amount_paid', 'Net Amount Paid', 'number', 'decimal', 18, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'date_of_payment', 'Date of Payment', 'date', 'date', 19, FALSE, TRUE, FALSE),
    ('invoice-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 20, FALSE, TRUE, FALSE),
    ('invoice-register', 'receipt', 'received_on', 'Received on', 'date', 'date', 21, FALSE, TRUE, FALSE),
    ('invoice-register', 'receipt', 'challan_amount', 'Ch. Amount', 'number', 'decimal', 22, FALSE, TRUE, FALSE),
    ('invoice-register', 'receipt', 'challan_no', 'Ch. No.', 'text', 'string', 23, FALSE, TRUE, FALSE),
    ('invoice-register', 'receipt', 'receipt_remarks', 'Remarks', 'textarea', 'string', 24, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'contractor', 'Contractor', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'wo_no', 'WO No.', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'wo_revision_details', 'WO Rev Details', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'debit_note_no', 'Debit Note No.', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'entry_date', 'Date', 'date', 'date', 6, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'debit_details', 'Details of Debits', 'textarea', 'string', 7, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'raised_by', 'Raised By', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'authorised_by', 'Authorised by', 'text', 'string', 9, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'accepted_by', 'Accepted by', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'amount', 'Amount', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'debit_made_to_invoice_no', 'Debit made to Inv No.', 'text', 'string', 12, FALSE, TRUE, FALSE),
    ('debit-note-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 13, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'cost_head', 'Cost Head', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'department', 'Dept', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'pr_no', 'PR No.', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'entry_date', 'Date', 'date', 'date', 5, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'material_specifications', 'Material Sepcifications', 'textarea', 'string', 6, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'quantity', 'Quantity', 'number', 'decimal', 7, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'unit', 'Unit', 'text', 'string', 8, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'budget_rate', 'Budget Rate', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'amount', 'Amount', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('purchase-requisition-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 11, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'cost_head', 'Cost Head', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'cost_head_detail_1', 'Cost Head Details 1', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'cost_head_detail_2', 'Cost Head Details 2', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'department', 'Dept', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'pr_no', 'PR No', 'text', 'string', 6, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'po_no', 'PO No.', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'entry_date', 'Date', 'date', 'date', 8, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'agency_name', 'Name of the Agency', 'text', 'string', 9, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'quotation_ref_date', 'Quotation Ref & Date', 'text', 'string', 10, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'pan', 'PAN', 'text', 'string', 11, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'gst_no', 'GST No.', 'text', 'string', 12, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'po_details', 'PO Details', 'textarea', 'string', 13, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'po_value_excl_taxes', 'PO Value (Excl Taxes)', 'number', 'decimal', 14, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'gst_on_wo', 'GST on WO', 'number', 'decimal', 15, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'po_value_incl_taxes', 'PO Value (Incl Taxes)', 'number', 'decimal', 16, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'allocated_budget', 'Allocated Budget', 'number', 'decimal', 17, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'budget_difference', 'Diff in Budget - PO Value', 'number', 'decimal', 18, FALSE, TRUE, FALSE),
    ('purchase-order-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 19, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'sr_no', 'Sr. No.', 'text', 'string', 1, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'vendor', 'Vendor', 'text', 'string', 2, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'po_no', 'PO No', 'text', 'string', 3, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'po_revision_details', 'PO Rev Details', 'text', 'string', 4, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'invoice_no', 'Invoice No.', 'text', 'string', 5, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'invoice_date', 'Invoice Date', 'date', 'date', 6, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'invoice_status', 'Invoice Status', 'text', 'string', 7, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'gross_claimed_amount', 'Gross Claimed Amount', 'number', 'decimal', 8, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'gross_certified_amount', 'Gross Certified Amount', 'number', 'decimal', 9, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'gst', 'GST', 'number', 'decimal', 10, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'net_payable', 'Net Payable', 'number', 'decimal', 11, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'payment_due_on', 'Payment Due on', 'date', 'date', 12, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'payment_method', 'Payment Method', 'text', 'string', 13, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'payment_instrument_details', 'Payment Instrument Details', 'text', 'string', 14, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'net_amount_paid', 'Net Amount Paid', 'number', 'decimal', 15, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'date_of_payment', 'Date of Payment', 'date', 'date', 16, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'main', 'remarks', 'Remarks', 'textarea', 'string', 17, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'receipt', 'received_on', 'Received on', 'date', 'date', 18, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'receipt', 'challan_amount', 'Ch. Amount', 'number', 'decimal', 19, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'receipt', 'challan_no', 'Ch. No.', 'text', 'string', 20, FALSE, TRUE, FALSE),
    ('inventory-invoice-register', 'receipt', 'receipt_remarks', 'Remarks', 'textarea', 'string', 21, FALSE, TRUE, FALSE)
)
INSERT INTO register_fields (
  register_id,
  section_name,
  field_key,
  field_label,
  field_type,
  data_type,
  column_order,
  is_required,
  is_repeatable,
  is_header
)
SELECT
  r.id,
  fs.section_name,
  fs.field_key,
  fs.field_label,
  fs.field_type,
  fs.data_type,
  fs.column_order,
  fs.is_required,
  fs.is_repeatable,
  fs.is_header
FROM field_seed fs
JOIN registers r
  ON r.slug = fs.register_slug
 AND r.organization_id IS NULL
ON CONFLICT (register_id, field_key) DO NOTHING;

INSERT INTO form_templates (
  register_id,
  name,
  version,
  schema_json,
  validation_rules,
  is_active,
  is_published,
  published_at
)
SELECT
  r.id,
  r.name || ' v1',
  1,
  jsonb_build_object(
    'register_slug', r.slug,
    'sheet_name', r.workbook_sheet_name,
    'fields',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'key', rf.field_key,
            'label', rf.field_label,
            'section', rf.section_name,
            'field_type', rf.field_type,
            'data_type', rf.data_type,
            'order', rf.column_order,
            'required', rf.is_required,
            'repeatable', rf.is_repeatable
          )
          ORDER BY rf.column_order
        )
        FROM register_fields rf
        WHERE rf.register_id = r.id
      ),
      '[]'::jsonb
    )
  ),
  '{}'::jsonb,
  TRUE,
  TRUE,
  NOW()
FROM registers r
WHERE r.organization_id IS NULL
ON CONFLICT (register_id, version) DO NOTHING;

COMMIT;
