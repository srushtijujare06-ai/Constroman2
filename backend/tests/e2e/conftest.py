import os

import pytest
from httpx import Client, Response

BASE_URL = os.getenv("API_URL", "http://127.0.0.1:8000")


@pytest.fixture(scope="session")
def api() -> Client:
    return Client(base_url=BASE_URL)


@pytest.fixture(scope="session")
def admin_token(api: Client) -> str:
    resp: Response = api.post(
        "/auth/login",
        json={
            "organization_slug": "constroman",
            "org_password": "org123",
            "email": "admin@constroman.com",
            "password": "admin123",
            "role": "admin",
        },
    )
    assert resp.status_code == 200, f"login failed: {resp.text}"
    data = resp.json()
    return data["access_token"]


@pytest.fixture(scope="session")
def auth_headers(admin_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {admin_token}"}
