# Constroman Backend

FastAPI backend for the existing `frontend-app` Next.js App Router application.

## Integration Flow

The frontend can call this API from `http://localhost:8000`. CORS is enabled for `http://localhost:3000` and `http://127.0.0.1:3000`.

Dynamic forms are stored in the existing database tables:

- `form_categories`: list of available form/register types.
- `form_templates`: active JSONB template definitions for each category.
- `form_submissions`: JSONB user-entered form values tied to a report.

The frontend flow is:

1. Load `/categories`.
2. Load `/templates/{category_id}` when a form/register is opened.
3. Render the fields from `schema_json` and optional `ui_schema`.
4. Create or select a report with `/reports`.
5. Save the entered values with `POST /submissions`.
6. Read saved values for a report with `/submissions/{report_id}`.

No separate tables are created for Material Issue Register, Material Receipt Register, Departmental Labour Register, RFI Register, Drawing Register, Safety Register, or QC Register. They are represented by category, template, and submission rows.

## Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` so `DATABASE_URL` points at the existing PostgreSQL database.

## Run

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

API docs:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/redoc`

## Alembic

Alembic is configured for the SQLAlchemy model metadata. Because the database schema already exists, review generated migrations before applying them.

```bash
cd backend
alembic revision --autogenerate -m "sync models"
alembic upgrade head
```

## Endpoints

### `GET /health`

Response:

```json
{
  "status": "ok"
}
```

### `GET /categories`

Response:

```json
[
  {
    "id": 1,
    "name": "Material Issue Register",
    "slug": "material-issue-register",
    "description": "Tracks issued material",
    "sort_order": 1,
    "is_active": true
  }
]
```

### `GET /templates/{category_id}`

Example:

```bash
curl http://127.0.0.1:8000/templates/1
```

Response:

```json
[
  {
    "id": 4,
    "category_id": 1,
    "name": "Material Issue Register v1",
    "version": 1,
    "schema_json": {
      "fields": [
        { "name": "material_name", "type": "text", "label": "Material Name" },
        { "name": "qty_issued", "type": "number", "label": "Qty Issued" }
      ]
    },
    "ui_schema": null,
    "is_active": true
  }
]
```

### `POST /reports`

Request:

```bash
curl -X POST http://127.0.0.1:8000/reports \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "report_date": "2026-06-19",
    "title": "Daily Site Report",
    "status": "draft",
    "weather": { "temp_at_12pm": 34, "rain_start": "14:30", "rain_end": "16:00" }
  }'
```

Response:

```json
{
  "id": 2,
  "project_id": 1,
  "subproject_id": null,
  "report_date": "2026-06-19",
  "title": "Daily Site Report",
  "status": "draft",
  "weather": { "temp_at_12pm": 34, "rain_start": "14:30", "rain_end": "16:00" },
  "prepared_by_id": null,
  "created_at": "2026-06-19T10:00:00Z",
  "updated_at": null
}
```

### `GET /reports`

Optional filter:

```bash
curl "http://127.0.0.1:8000/reports?project_id=1"
```

### `GET /reports/{id}`

```bash
curl http://127.0.0.1:8000/reports/2
```

### `POST /submissions`

Request:

```bash
curl -X POST http://127.0.0.1:8000/submissions \
  -H "Content-Type: application/json" \
  -d '{
    "report_id": 2,
    "category_id": 1,
    "form_data": {
      "material_name": "Cement",
      "qty_issued": 50
    }
  }'
```

Response:

```json
{
  "id": 10,
  "report_id": 2,
  "category_id": 1,
  "template_id": 4,
  "submitted_by_id": null,
  "form_data": {
    "material_name": "Cement",
    "qty_issued": 50
  },
  "created_at": "2026-06-19T10:05:00Z",
  "updated_at": null
}
```

### `GET /submissions/{report_id}`

```bash
curl http://127.0.0.1:8000/submissions/2
```

### `GET /projects`

Response:

```json
[
  {
    "id": 1,
    "organization_id": 1,
    "name": "Skyline Tower",
    "location": "Bandra Kurla Complex, Mumbai",
    "start_date": "2024-01-15",
    "end_date": null,
    "status": "active",
    "subprojects": []
  }
]
```

### `GET /projects/{id}`

```bash
curl http://127.0.0.1:8000/projects/1
```
