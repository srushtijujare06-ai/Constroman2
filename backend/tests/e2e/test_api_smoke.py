from httpx import Client, Response


def test_health(api: Client):
    resp: Response = api.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_login(api: Client, admin_token: str):
    assert len(admin_token) > 20


def test_auth_me(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get("/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    user = resp.json()
    assert user["email"] == "admin@constroman.com"
    assert user["role"] == "admin"


def test_list_projects(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get("/projects", headers=auth_headers)
    assert resp.status_code == 200
    projects = resp.json()
    assert len(projects) >= 1


def test_list_users(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get("/users", headers=auth_headers)
    assert resp.status_code == 200
    users = resp.json()
    assert len(users) >= 2  # admin + employee seeded
    emails = {u["email"] for u in users}
    assert "admin@constroman.com" in emails
    assert "employee@constroman.com" in emails


def test_create_report(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.post(
        "/reports",
        headers=auth_headers,
        json={
            "project_id": 1,
            "report_date": "2026-06-25",
            "title": "Test Report via pytest",
            "status": "draft",
        },
    )
    assert resp.status_code == 201, resp.text
    report = resp.json()
    assert report["organization_id"] == 1
    assert report["project_id"] == 1
    assert report["status"] == "draft"
    assert report["title"] == "Test Report via pytest"
    assert report["id"] >= 1


def test_create_and_get_submission(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.post(
        "/submissions",
        headers=auth_headers,
        json={
            "organization_id": 1,
            "project_id": 1,
            "register_id": 1,
            "template_id": 26,
            "report_id": 2,
            "form_data": {"project_name": "pytest smoke", "report_date": "2026-06-25"},
        },
    )
    assert resp.status_code == 201, resp.text
    sub = resp.json()
    sub_id = sub["id"]
    assert sub["status"] == "draft"

    # GET the submission back
    resp2: Response = api.get(f"/submissions/{sub_id}", headers=auth_headers)
    assert resp2.status_code == 200
    assert resp2.json()["id"] == sub_id

    # Update status
    resp3: Response = api.patch(
        f"/submissions/{sub_id}/status?status=submitted", headers=auth_headers
    )
    assert resp3.status_code == 200, resp3.text
    assert resp3.json()["status"] == "submitted"


def test_list_submissions(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get(
        "/submissions?organization_id=1", headers=auth_headers
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1
    assert len(data["items"]) >= 1


def test_create_attachment(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.post(
        "/attachments?organization_id=1",
        headers=auth_headers,
        json={
            "submission_id": 1,
            "file_name": "test.txt",
            "file_size": 10,
            "mime_type": "text/plain",
            "storage_path": "/tmp/test.txt",
            "storage_provider": "local",
        },
    )
    assert resp.status_code == 201, resp.text
    att = resp.json()
    assert att["file_name"] == "test.txt"


def test_create_remark(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.post(
        "/remarks?report_id=2&content=pytest%20remark&is_admin_only=false",
        headers=auth_headers,
    )
    assert resp.status_code == 201, resp.text
    remark = resp.json()
    assert remark["remark_text"] == "pytest remark"


def test_list_registers(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get("/registers", headers=auth_headers)
    assert resp.status_code == 200
    regs = resp.json()
    assert len(regs) >= 10
    slugs = {r["slug"] for r in regs}
    assert "site-report" in slugs
    assert "material-receipt-register" in slugs


def test_list_templates(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get("/templates/1", headers=auth_headers)
    assert resp.status_code == 200
    tpls = resp.json()
    assert len(tpls) >= 1


def test_audit_logs(api: Client, auth_headers: dict[str, str]):
    resp: Response = api.get(
        "/audit-logs?organization_id=1", headers=auth_headers
    )
    assert resp.status_code == 200
    logs = resp.json()
    assert len(logs) >= 1
