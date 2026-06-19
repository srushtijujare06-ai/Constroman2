# Constroman Database Architecture

## Multi-Tenant SaaS Design for Dynamic Construction Registers

---

## Design Philosophy

The system uses a **template-driven JSONB architecture** where all register types (Material Receipt, Site Diary, RFI, Safety, etc.) share a single set of generic tables. Register structure is defined at runtime via JSONB templates — no DDL changes are needed to add new register types. This enables unlimited custom forms without database migrations.

---

## ERD Overview

```
organizations (1) ──< (N) users
organizations (1) ──< (N) projects
organizations (1) ──< (N) registers
projects (1) ──< (N) subprojects
projects (1) ──< (N) project_assignments
projects (1) ──< (N) reports
projects (1) ──< (N) submissions
reports (1) ──< (N) submissions
registers (1) ──< (N) form_templates
registers (1) ──< (N) submissions
form_templates (1) ──< (N) submissions
submissions (1) ──< (N) attachments
submissions (1) ──< (N) submission_comments
submissions (1) ──< (N) audit_logs
users (1) ──< (N) submissions (as submitter)
users (1) ──< (N) submission_comments
users (1) ──< (N) audit_logs
```

---

## Tables

### 1. organizations

Multi-tenant root. Every row across the system is scoped to an organization.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| name | `VARCHAR(255)` | NOT NULL | |
| slug | `VARCHAR(255)` | UNIQUE, NOT NULL | URL-friendly identifier |
| domain | `VARCHAR(255)` | NULL | Custom domain for white-label |
| logo_url | `VARCHAR(500)` | NULL | |
| is_active | `BOOLEAN` | NOT NULL, DEFAULT true | Soft-disable for billing |
| settings | `JSONB` | NOT NULL, DEFAULT '{}' | Org-level preferences |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `UNIQUE` on `slug`
- `INDEX` on `is_active` (for tenant filtering)

---

### 2. users

Multi-tenant users. A user belongs to exactly one organization.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| name | `VARCHAR(255)` | NOT NULL | |
| email | `VARCHAR(255)` | NOT NULL | |
| password_hash | `VARCHAR(255)` | NOT NULL | |
| role | `VARCHAR(50)` | NOT NULL, DEFAULT 'member' | `admin`, `manager`, `engineer`, `member`, `viewer` |
| phone | `VARCHAR(50)` | NULL | |
| avatar_url | `VARCHAR(500)` | NULL | |
| is_active | `BOOLEAN` | NOT NULL, DEFAULT true | |
| last_login_at | `TIMESTAMPTZ` | NULL | |
| preferences | `JSONB` | NOT NULL, DEFAULT '{}' | User-level UI preferences |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |

**Indexes:**
- `PK` on `id`
- `UNIQUE` on `(organization_id, email)` — no duplicate emails per org
- `INDEX` on `organization_id` — tenant-scoped queries
- `INDEX` on `role` — role-based filtering

---

### 3. projects

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| name | `VARCHAR(255)` | NOT NULL | |
| location | `VARCHAR(255)` | NULL | |
| start_date | `DATE` | NULL | |
| end_date | `DATE` | NULL | |
| status | `VARCHAR(50)` | NOT NULL, DEFAULT 'active' | `active`, `completed`, `on-hold`, `cancelled` |
| code | `VARCHAR(50)` | NULL | Short project code (e.g. "ST-2024") |
| metadata | `JSONB` | NOT NULL, DEFAULT '{}' | Extensible project metadata |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(organization_id, status)` — tenant + status filtering
- `INDEX` on `organization_id`

---

### 4. subprojects

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| project_id | `INTEGER` | FK → projects.id, NOT NULL | |
| name | `VARCHAR(255)` | NOT NULL | |
| location | `VARCHAR(255)` | NULL | |
| start_date | `DATE` | NULL | |
| end_date | `DATE` | NULL | |
| status | `VARCHAR(50)` | NOT NULL, DEFAULT 'active' | |
| metadata | `JSONB` | NOT NULL, DEFAULT '{}' | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(project_id, status)`
- `INDEX` on `project_id`

---

### 5. project_assignments

Maps users to projects with a role.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| project_id | `INTEGER` | FK → projects.id, NOT NULL | |
| user_id | `INTEGER` | FK → users.id, NOT NULL | |
| role | `VARCHAR(100)` | NULL | Project-level role override |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |

**Indexes:**
- `PK` on `id`
- `UNIQUE` on `(project_id, user_id)` — one assignment per user per project
- `INDEX` on `user_id` — find all projects for a user

---

### 6. reports

A daily grouping container. A report represents "today's paperwork" for a project. Submissions can optionally belong to a report to enable the daily-site-report workflow.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| project_id | `INTEGER` | FK → projects.id, NOT NULL | |
| subproject_id | `INTEGER` | FK → subprojects.id, NULL | |
| report_date | `DATE` | NOT NULL | |
| title | `VARCHAR(255)` | NULL | |
| status | `VARCHAR(50)` | NOT NULL, DEFAULT 'draft' | `draft`, `submitted`, `reviewed`, `approved`, `rejected` |
| weather | `JSONB` | NULL | Quick weather summary for the day |
| prepared_by_id | `INTEGER` | FK → users.id, NULL | |
| notes | `TEXT` | NULL | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(project_id, report_date)` — daily lookup
- `INDEX` on `(project_id, status)`
- `INDEX` on `report_date` — date-range queries

---

### 7. registers

**This is the core of the dynamic form system.** Each row defines a type of register/form. A "register" corresponds to a construction document type (e.g., Material Receipt Register, RFI Register, Safety Register). Registers are configurable at runtime.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | Scope to tenant |
| name | `VARCHAR(255)` | NOT NULL | Human-readable (e.g. "Material Receipt Register") |
| slug | `VARCHAR(255)` | NOT NULL | URL-safe (e.g. "material-receipt-register") |
| description | `TEXT` | NULL | |
| icon | `VARCHAR(100)` | NULL | Icon identifier for UI |
| sort_order | `INTEGER` | NOT NULL, DEFAULT 0 | Display ordering |
| scope | `VARCHAR(20)` | NOT NULL, DEFAULT 'project' | `project` or `organization` — whether entries belong to a project or org-wide |
| config | `JSONB` | NOT NULL, DEFAULT '{}' | See JSONB structures below |
| is_active | `BOOLEAN` | NOT NULL, DEFAULT true | Soft-disable without data loss |
| is_system | `BOOLEAN` | NOT NULL, DEFAULT false | System registers cannot be deleted |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `UNIQUE` on `(organization_id, slug)` — unique register per tenant
- `INDEX` on `(organization_id, is_active)` — active register listing
- `INDEX` on `sort_order` — display ordering

---

### 8. form_templates

Versioned JSONB schemas that define the fields for each register. When a template is updated, previous submissions keep their version reference for historical accuracy.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| register_id | `INTEGER` | FK → registers.id, NOT NULL | |
| name | `VARCHAR(255)` | NOT NULL | e.g. "Material Receipt v2" |
| version | `INTEGER` | NOT NULL | Auto-incrementing per register |
| schema_json | `JSONB` | NOT NULL | Field definitions (see JSONB structures) |
| ui_schema | `JSONB` | NULL | Layout hints (columns, sections, ordering) |
| validation_rules | `JSONB` | NOT NULL, DEFAULT '{}' | Cross-field validation rules |
| is_active | `BOOLEAN` | NOT NULL, DEFAULT true | |
| is_published | `BOOLEAN` | NOT NULL, DEFAULT false | Published templates can receive submissions |
| published_at | `TIMESTAMPTZ` | NULL | |
| created_by_id | `INTEGER` | FK → users.id, NULL | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `UNIQUE` on `(register_id, version)` — one version number per register
- `INDEX` on `(register_id, is_active, is_published)` — find current template
- `INDEX` on `register_id`

---

### 9. submissions

Each row is one entry in a register. For "Material Receipt Register", one row = one material receipt entry. Submissions are decoupled from reports — they can exist standalone (for ongoing registers) or be grouped under a daily report.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | Direct tenant link for efficient queries |
| project_id | `INTEGER` | FK → projects.id, NULL | NULL for org-scoped registers |
| register_id | `INTEGER` | FK → registers.id, NOT NULL | |
| template_id | `INTEGER` | FK → form_templates.id, NOT NULL | Snapshot of which template version |
| report_id | `INTEGER` | FK → reports.id, NULL | Optional grouping under daily report |
| submission_date | `DATE` | NOT NULL, DEFAULT CURRENT_DATE | The date this entry pertains to |
| title | `VARCHAR(255)` | NULL | Optional human-readable title |
| status | `VARCHAR(20)` | NOT NULL, DEFAULT 'draft' | `draft`, `submitted`, `reviewed`, `approved`, `rejected` |
| form_data | `JSONB` | NOT NULL | The actual field values (see JSONB structures) |
| serial_no | `INTEGER` | NULL | Auto-incrementing serial per (register_id, project_id, year) |
| submitted_by_id | `INTEGER` | FK → users.id, NULL | |
| submitted_at | `TIMESTAMPTZ` | NULL | |
| metadata | `JSONB` | NOT NULL, DEFAULT '{}' | Extensible metadata (source, import info, etc.) |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(organization_id, register_id, status)` — tenant register listing
- `INDEX` on `(organization_id, register_id, submission_date)` — date-range queries
- `INDEX` on `(project_id, register_id)` — project-scoped register listing
- `INDEX` on `(organization_id, register_id, project_id)` — combined scope query
- `INDEX` on `report_id` — find all submissions in a report
- `INDEX` on `submitted_by_id`
- `INDEX` on `submission_date`
- `GIN INDEX` on `form_data` — JSONB queries (see filtering section)

---

### 10. attachments

File attachments linked to a submission or general entity.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| submission_id | `INTEGER` | FK → submissions.id, NULL | Direct link to submission |
| entity_type | `VARCHAR(50)` | NULL | Polymorphic: 'submission', 'report', 'comment' |
| entity_id | `INTEGER` | NULL | Polymorphic entity ID |
| file_name | `VARCHAR(500)` | NOT NULL | Original filename |
| file_size | `INTEGER` | NOT NULL | Size in bytes |
| mime_type | `VARCHAR(100)` | NOT NULL | |
| storage_path | `VARCHAR(1000)` | NOT NULL | Object storage key/path |
| storage_provider | `VARCHAR(50)` | NOT NULL, DEFAULT 'local' | `local`, `s3`, `gcs`, etc. |
| uploaded_by_id | `INTEGER` | FK → users.id, NULL | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(entity_type, entity_id)` — polymorphic lookup
- `INDEX` on `submission_id`
- `INDEX` on `organization_id`

---

### 11. submission_comments

Comments/remarks on individual submissions. Supports threaded replies via `parent_id`.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| submission_id | `INTEGER` | FK → submissions.id, NOT NULL | |
| parent_id | `INTEGER` | FK → submission_comments.id, NULL | For threaded replies |
| user_id | `INTEGER` | FK → users.id, NOT NULL | |
| content | `TEXT` | NOT NULL | |
| is_internal | `BOOLEAN` | NOT NULL, DEFAULT false | Internal notes vs client-facing |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `submission_id` — load all comments for a submission
- `INDEX` on `(parent_id)` — threaded replies
- `INDEX` on `user_id`

---

### 12. audit_logs

Immutable audit trail for all changes to submissions, reports, templates.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `BIGINT` | PK, IDENTITY | BIGINT for high volume |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| entity_type | `VARCHAR(50)` | NOT NULL | `submission`, `report`, `template` |
| entity_id | `INTEGER` | NOT NULL | |
| action | `VARCHAR(50)` | NOT NULL | `created`, `updated`, `status_changed`, `submitted`, `approved`, `rejected`, `commented`, `file_uploaded` |
| user_id | `INTEGER` | FK → users.id, NULL | Who performed the action |
| changes | `JSONB` | NULL | Before/after diff (see JSONB structures) |
| metadata | `JSONB` | NULL | Extra context (IP, user-agent, etc.) |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(entity_type, entity_id, created_at)` — timeline for an entity
- `INDEX` on `(organization_id, entity_type, created_at)` — activity feed
- `INDEX` on `user_id` — user action history
- `INDEX` on `created_at` — time-range queries

---

### 13. approval_workflows (optional, future)

Defines approval chains per register. Each register can have a configurable workflow (who needs to approve, in what order).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `INTEGER` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| register_id | `INTEGER` | FK → registers.id, NOT NULL, UNIQUE | One workflow per register |
| steps | `JSONB` | NOT NULL | Array of approval steps |
| is_active | `BOOLEAN` | NOT NULL, DEFAULT true | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |
| updated_at | `TIMESTAMPTZ` | NULL | |

---

### 14. notifications (future)

In-app notification queue for events (submission submitted, approved, rejected, commented).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | `BIGINT` | PK, IDENTITY | |
| organization_id | `INTEGER` | FK → organizations.id, NOT NULL | |
| user_id | `INTEGER` | FK → users.id, NOT NULL | Recipient |
| type | `VARCHAR(50)` | NOT NULL | `submission_submitted`, `submission_approved`, `comment_added`, etc. |
| title | `VARCHAR(255)` | NOT NULL | |
| body | `TEXT` | NULL | |
| link | `VARCHAR(500)` | NULL | Deep link to relevant entity |
| is_read | `BOOLEAN` | NOT NULL, DEFAULT false | |
| read_at | `TIMESTAMPTZ` | NULL | |
| created_at | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | |

**Indexes:**
- `PK` on `id`
- `INDEX` on `(user_id, is_read, created_at)` — unread notification feed

---

## JSONB Structures

### registers.config

Register-level configuration that defines behavior.

```jsonc
{
  "allow_multiple_per_day": true,
  // Can multiple entries be created per day? (true for material receipt, false for site report)

  "enable_serial_number": true,
  // Auto-generate serial numbers per register/project/year

  "serial_format": "MR-{year}-{serial}",
  // Format string for display

  "enable_workflow": true,
  // Whether approval workflow is enabled

  "default_status": "draft",
  // Default status for new submissions

  "available_statuses": ["draft", "submitted", "reviewed", "approved", "rejected"],
  // Override the default status list

  "enable_attachments": true,
  // Whether file upload is allowed

  "enable_comments": true,
  // Whether comments/remarks are enabled

  "date_field": "submission_date",
  // Which field drives the primary date

  "group_by_field": null,
  // Field name for grouping entries in the UI (e.g., "material_name")

  "summary_fields": ["material_name", "quantity"],
  // Fields shown in list views

  "searchable_fields": ["po_no", "supplier", "material_name"],
  // Fields indexed for full-text search

  "columns": [
    { "field": "serial_no", "label": "#", "width": 60 },
    { "field": "date", "label": "Date", "width": 120 },
    { "field": "material_name", "label": "Material", "flex": 1 }
  ]
  // List view column configuration
}
```

---

### form_templates.schema_json

Defines the fields in a register. This is the core of the dynamic form engine.

```jsonc
{
  "fields": [
    {
      "name": "material_name",
      "type": "text",
      "label": "Material Name",
      "placeholder": "Enter material name",
      "required": true,
      "default": null,
      "readonly": false,
      "disabled": false,
      "hidden": false,
      "help_text": "Full description of the received material",
      "validation": {
        "min_length": 2,
        "max_length": 500,
        "pattern": null
      }
    },
    {
      "name": "po_no",
      "type": "text",
      "label": "PO Number",
      "required": true
    },
    {
      "name": "quantity_received",
      "type": "number",
      "label": "Qty Received",
      "required": true,
      "validation": {
        "min": 0,
        "max": 999999.99,
        "decimal_places": 2
      }
    },
    {
      "name": "quantity_rejected",
      "type": "number",
      "label": "Qty Rejected",
      "default": 0,
      "validation": {
        "min": 0
      }
    },
    {
      "name": "unit",
      "type": "dropdown",
      "label": "Unit",
      "required": true,
      "options": [
        { "value": "mt", "label": "Metric Ton" },
        { "value": "bags", "label": "Bags" },
        { "value": "cum", "label": "Cubic Meter" },
        { "value": "sqm", "label": "Square Meter" },
        { "value": "nos", "label": "Numbers" },
        { "value": "rmt", "label": "Running Meter" }
      ]
    },
    {
      "name": "receipt_date",
      "type": "date",
      "label": "Receipt Date",
      "required": true,
      "default": "today"
    },
    {
      "name": "time_in",
      "type": "time",
      "label": "Time In"
    },
    {
      "name": "supplier",
      "type": "text",
      "label": "Supplier Name"
    },
    {
      "name": "grn_no",
      "type": "text",
      "label": "GRN Number"
    },
    {
      "name": "inspection_status",
      "type": "radio",
      "label": "Inspection Status",
      "options": [
        { "value": "passed", "label": "Passed" },
        { "value": "failed", "label": "Failed" },
        { "value": "pending", "label": "Pending" }
      ],
      "default": "pending"
    },
    {
      "name": "has_defects",
      "type": "checkbox",
      "label": "Has Defects",
      "default": false
    },
    {
      "name": "defect_details",
      "type": "textarea",
      "label": "Defect Details",
      "hidden": true,
      "show_if": { "field": "has_defects", "equals": true }
      // Conditional visibility
    },
    {
      "name": "quantity_accepted",
      "type": "number",
      "label": "Qty Accepted",
      "validation": {
        "min": 0
      },
      "calculated": true,
      "formula": "{quantity_received} - {quantity_rejected}"
      // Auto-calculated field
    },
    {
      "name": "photos",
      "type": "file",
      "label": "Upload Photos",
      "accept": "image/*",
      "multiple": true,
      "max_size_mb": 10,
      "max_files": 5
    },
    {
      "name": "remarks",
      "type": "textarea",
      "label": "Remarks",
      "required": false
    }
  ]
}
```

### Sample register: Departmental Labour Register

```jsonc
{
  "fields": [
    {
      "name": "sr_no", "type": "number", "label": "Sr No",
      "calculated": true, "formula": "{serial_no}"
    },
    {
      "name": "date", "type": "date", "label": "Date", "default": "today"
    },
    {
      "name": "challan_no", "type": "text", "label": "Challan No", "required": true
    },
    {
      "name": "sub_contractor", "type": "text", "label": "Sub Contractor Name"
    },
    {
      "name": "labour_name", "type": "text", "label": "Name of Labour", "required": true
    },
    {
      "name": "category", "type": "dropdown", "label": "Labour Category",
      "options": [
        { "value": "mason", "label": "Mason" },
        { "value": "carpenter", "label": "Carpenter" },
        { "value": "fitter", "label": "Fitter" },
        { "value": "helper", "label": "Helper" },
        { "value": "skilled", "label": "Skilled" },
        { "value": "unskilled", "label": "Unskilled" }
      ]
    },
    {
      "name": "mandays", "type": "number", "label": "No of Mandays", "required": true
    },
    {
      "name": "work_done", "type": "textarea", "label": "Work Done Details"
    },
    {
      "name": "quantity", "type": "number", "label": "Approx Quantity"
    },
    {
      "name": "unit", "type": "text", "label": "Unit"
    },
    {
      "name": "recovery_from", "type": "text", "label": "Recovery From"
    },
    {
      "name": "recovery_rate", "type": "number", "label": "Recovery Rate"
    },
    {
      "name": "recovery_amount", "type": "number", "label": "Recovery Amount",
      "calculated": true,
      "formula": "{mandays} * {recovery_rate}"
    },
    {
      "name": "authorised_by", "type": "text", "label": "Authorised By"
    },
    {
      "name": "remarks", "type": "textarea", "label": "Remarks"
    }
  ]
}
```

### Sample register: RFI Register

```jsonc
{
  "fields": [
    { "name": "rfi_no", "type": "text", "label": "RFI Number", "required": true },
    { "name": "date", "type": "date", "label": "Date", "default": "today" },
    { "name": "location", "type": "text", "label": "Location/Area" },
    { "name": "subject", "type": "text", "label": "Subject", "required": true },
    { "name": "description", "type": "textarea", "label": "Description of Issue", "required": true },
    { "name": "priority", "type": "radio", "label": "Priority",
      "options": [
        { "value": "low", "label": "Low" },
        { "value": "medium", "label": "Medium" },
        { "value": "high", "label": "High" },
        { "value": "critical", "label": "Critical" }
      ],
      "default": "medium"
    },
    { "name": "raised_by", "type": "text", "label": "Raised By" },
    { "name": "status", "type": "dropdown", "label": "RFI Status",
      "options": [
        { "value": "open", "label": "Open" },
        { "value": "under_review", "label": "Under Review" },
        { "value": "clarification", "label": "Clarification Required" },
        { "value": "closed", "label": "Closed" }
      ],
      "default": "open"
    },
    { "name": "response", "type": "textarea", "label": "Consultant/Client Response" },
    { "name": "response_date", "type": "date", "label": "Response Date" },
    { "name": "closure_date", "type": "date", "label": "Closure Date" },
    { "name": "attachments", "type": "file", "label": "Supporting Documents", "multiple": true }
  ]
}
```

---

### submissions.form_data

Actual values stored when a user fills out a form.

```jsonc
{
  "material_name": "TMT Steel Bars Fe500D 12mm dia",
  "po_no": "PO-2026-0078",
  "quantity_received": 12.5,
  "quantity_rejected": 0.5,
  "unit": "mt",
  "receipt_date": "2026-06-16",
  "time_in": "08:30",
  "supplier": "SAIL Steel Depot",
  "grn_no": "GRN-0341",
  "inspection_status": "passed",
  "has_defects": true,
  "defect_details": "Surface rust on 0.5 MT",
  "quantity_accepted": 12.0,
  "photos": [
    {
      "id": 1,
      "file_name": "material_photo_1.jpg",
      "url": "/storage/org_1/submissions/42/photo_1.jpg"
    }
  ],
  "remarks": "0.5 MT rejected due to surface rust"
}
```

---

### audit_logs.changes

Before/after diff for status changes and edits.

```jsonc
// For a status change:
{
  "status": {
    "from": "draft",
    "to": "submitted"
  }
}

// For a field edit:
{
  "form_data": {
    "quantity_received": {
      "from": 10.0,
      "to": 12.5
    },
    "supplier": {
      "from": null,
      "to": "SAIL Steel Depot"
    }
  }
}
```

---

### approval_workflows.steps

```jsonc
[
  {
    "step": 1,
    "name": "Engineer Review",
    "assigned_role": "engineer",
    "required_actions": ["approve", "reject", "request_changes"],
    "timeout_hours": 48
  },
  {
    "step": 2,
    "name": "Manager Approval",
    "assigned_role": "manager",
    "required_actions": ["approve", "reject"],
    "timeout_hours": 72
  }
]
```

---

## Key Design Decisions

### 1. Why registers are separate from form_categories

`registers` is the renamed, enhanced version of the current `form_categories`. The rename clarifies that each register is a first-class business entity (not just a "category" of form). Additional features: scope control (project vs org), config JSONB, icon, sort order.

### 2. Why submissions are decoupled from reports

In the current system, every `form_submission` requires a `report_id`. This forces all entries to be grouped under a daily report. But many registers (RFI, Drawing Register, Safety Register) are ongoing logs, not daily reports. Decoupling allows:
- Standalone entries in an ongoing register
- Optional grouping under a daily report when needed
- The same submission can appear in a daily report and also exist independently

### 3. Why organization_id is denormalized into submissions

Every submission has a direct `organization_id` even though it can be reached through `register_id → registers → organization_id`. This denormalization is intentional:
- Eliminates a 3-table JOIN for every tenant-scoped query
- Makes row-level security (RLS) policies simpler and faster
- The slight storage overhead is negligible for the query performance gain

### 4. JSONB indexing strategy

To query within `form_data` efficiently:
```sql
-- GIN index for general JSONB queries
CREATE INDEX idx_submissions_form_data ON submissions USING GIN (form_data jsonb_path_ops);

-- Partial indexes for frequently-queried fields
CREATE INDEX idx_submissions_po_number ON submissions
  USING BTREE ((form_data->>'po_no'))
  WHERE register_id = 1;
```

The GIN index with `jsonb_path_ops` is more compact and faster for path-based queries (e.g., `form_data @> '{"material_name": "Cement"}'`). Add register-specific partial BTREE indexes for fields used in sorting, grouping, or frequent filtering.

### 5. Soft-delete policy

All tables use `is_active` boolean flags rather than hard deletes. This is critical for:
- Audit trail integrity (deleting a submission would break its history)
- Regulatory compliance (construction records must be retained)
- Accidental deletion recovery

### 6. Serial numbering

The `serial_no` column on submissions provides auto-incrementing serial numbers per register, project, and year. This is a common requirement for construction registers (MR-2026-001, MR-2026-002). Implementation uses a sequence or calculated on insert:
```sql
SELECT COALESCE(MAX(serial_no), 0) + 1
FROM submissions
WHERE register_id = $1 AND project_id = $2
  AND EXTRACT(YEAR FROM submission_date) = $3;
```

### 7. Calculated fields

Calculated fields are evaluated at the application layer when the form is rendered (for display) and when the submission is saved (for persistence). The formula engine supports:
- Arithmetic: `{quantity_received} - {quantity_rejected}`
- String concat: `{first_name} || ' ' || {last_name}`
- Conditionals: `IF({quantity_rejected} > 0, 'partial', 'full')`
- Aggregates: `SUM({previous} + {today})`

---

## Entity-Relationship Summary

```
organizations
├── users (N)
├── projects (N)
│   ├── subprojects (N)
│   ├── project_assignments (N)
│   └── reports (N)
│       └── submissions (N, optional grouping)
├── registers (N)
│   ├── form_templates (N, versioned)
│   └── submissions (N)
│       ├── attachments (N)
│       ├── submission_comments (N, threaded)
│       └── audit_logs (N, immutable)
└── approval_workflows (N, per register)
```

### Register ← → Submission relationship

The core dynamic data flow:

1. A tenant defines a **register** (e.g., "Material Receipt Register")
2. They create a **template** with a JSONB schema defining the fields
3. Users create **submissions** against that template
4. Each submission stores its values in `form_data` JSONB
5. Attachments, comments, and audit logs link to the submission
6. Submissions can optionally be grouped under a daily **report** for the daily-site-report workflow

This design supports unlimited register types without any schema changes, while the fixed relational tables handle multi-tenancy, access control, workflow, and audit history.
