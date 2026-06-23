from datetime import date

from sqlalchemy import text

from app.auth.utils import hash_password
from app.database import SessionLocal, engine, Base
from app.models import (
    Organization,
    Role,
    User,
    Project,
    Register,
    FormTemplate,
)


def ensure_schema():
    """Create tables using raw SQL to avoid SQLAlchemy index conflicts."""
    meta = Base.metadata
    tables = meta.sorted_tables
    with engine.begin() as conn:
        existing = set(
            row[0]
            for row in conn.execute(
                text("SELECT tablename FROM pg_tables WHERE schemaname='public'")
            ).all()
        )
        for table in tables:
            if table.name not in existing:
                table.create(conn, checkfirst=True)
                print(f"  Created table: {table.name}")
        for table in tables:
            for index in table.indexes:
                if index.name:
                    exists = conn.execute(
                        text(
                            "SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname=:name"
                        ),
                        {"name": index.name},
                    ).first()
                    if not exists:
                        index.create(conn)
                        print(f"  Created index: {index.name}")


ensure_schema()


def seed():
    ensure_schema()
    db = SessionLocal()

    if db.query(Organization).count() > 0:
        print("Database already seeded, skipping.")
        db.close()
        return

    admin_role = Role(name="admin", description="Organization administrator")
    employee_role = Role(name="employee", description="Regular employee")
    db.add_all([admin_role, employee_role])
    db.flush()

    org = Organization(
        name="Constroman Constructions Pvt Ltd",
        slug="constroman",
        password_hash=hash_password("org123"),
        is_active=True,
        settings={"timezone": "Asia/Kolkata"},
    )
    db.add(org)
    db.flush()

    user = User(
        organization_id=org.id,
        name="Admin User",
        email="admin@constroman.com",
        password_hash=hash_password("admin123"),
        role_id=admin_role.id,
        role="admin",
        is_active=True,
    )
    db.add(user)

    employee = User(
        organization_id=org.id,
        name="Employee User",
        email="employee@constroman.com",
        password_hash=hash_password("emp123"),
        role_id=employee_role.id,
        role="employee",
        is_active=True,
    )
    db.add(employee)

    projects_data = [
        {
            "name": "Skyline Tower",
            "location": "Bandra Kurla Complex, Mumbai",
            "start_date": date(2024, 1, 15),
            "status": "active",
            "code": "ST-2024",
        },
        {
            "name": "Green Valley Residency",
            "location": "Hinjewadi, Pune",
            "start_date": date(2024, 3, 1),
            "status": "active",
            "code": "GV-2024",
        },
    ]

    created_projects = []
    for p in projects_data:
        project = Project(
            organization_id=org.id,
            name=p["name"],
            location=p["location"],
            start_date=p["start_date"],
            status=p["status"],
            code=p["code"],
        )
        db.add(project)
        created_projects.append(project)
    db.flush()

    from app.models import ProjectAssignment
    if created_projects:
        assign = ProjectAssignment(
            project_id=created_projects[0].id,
            user_id=employee.id,
            role="viewer",
        )
        db.add(assign)

    registers_data = [
        {
            "name": "Site Report",
            "slug": "site-report",
            "sort_order": 1,
            "scope": "project",
            "config": {"allow_multiple_per_day": False},
        },
        {
            "name": "Weather Log",
            "slug": "weather-log",
            "sort_order": 2,
            "scope": "project",
            "config": {"allow_multiple_per_day": True},
        },
        {
            "name": "Site Diary",
            "slug": "site-diary",
            "sort_order": 3,
            "scope": "project",
            "config": {"allow_multiple_per_day": True},
        },
        {
            "name": "Hindrance Register",
            "slug": "hindrance-register",
            "sort_order": 4,
            "scope": "project",
            "config": {"enable_serial_number": True},
        },
        {
            "name": "Customer Milestones",
            "slug": "customer-milestones",
            "sort_order": 5,
            "scope": "project",
        },
        {
            "name": "Construction Milestones",
            "slug": "construction-milestones",
            "sort_order": 6,
            "scope": "project",
        },
        {
            "name": "Work & Labour",
            "slug": "work-labour",
            "sort_order": 7,
            "scope": "project",
        },
        {
            "name": "Dept. Labour Register",
            "slug": "dept-labour-register",
            "sort_order": 8,
            "scope": "project",
            "config": {"enable_serial_number": True},
        },
        {
            "name": "Material Receipt Register",
            "slug": "material-receipt-register",
            "sort_order": 9,
            "scope": "project",
            "config": {"enable_serial_number": True, "serial_format": "MR-{year}-{serial}"},
        },
        {
            "name": "Material Issue Register",
            "slug": "material-issue-register",
            "sort_order": 10,
            "scope": "project",
        },
        {
            "name": "RFI Register",
            "slug": "rfi-register",
            "sort_order": 11,
            "scope": "project",
            "config": {"enable_serial_number": True, "enable_workflow": True},
        },
        {
            "name": "Drawing Register",
            "slug": "drawing-register",
            "sort_order": 12,
            "scope": "project",
        },
        {
            "name": "Safety Register",
            "slug": "safety-register",
            "sort_order": 13,
            "scope": "project",
        },
        {
            "name": "Cube Test Register",
            "slug": "cube-test-register",
            "sort_order": 14,
            "scope": "project",
        },
    ]

    for r in registers_data:
        register = Register(
            organization_id=org.id,
            name=r["name"],
            slug=r["slug"],
            sort_order=r["sort_order"],
            scope=r.get("scope", "project"),
            config=r.get("config", {}),
            is_active=True,
        )
        db.add(register)
        db.flush()

        template = FormTemplate(
            register_id=register.id,
            name=f"{r['name']} v1",
            version=1,
            schema_json={
                "fields": [
                    {
                        "name": "notes",
                        "type": "textarea",
                        "label": "Notes",
                        "required": False,
                    }
                ]
            },
            is_active=True,
            is_published=True,
            published_at=__import__("datetime").datetime.now(),
            created_by_id=user.id,
        )
        db.add(template)

    db.commit()
    db.close()
    print("Database seeded successfully!")


if __name__ == "__main__":
    seed()
