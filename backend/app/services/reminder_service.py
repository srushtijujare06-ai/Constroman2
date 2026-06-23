from datetime import date, timedelta

from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.models import Notification, Project, Register, Report, User, ProjectAssignment


def check_missed_forms(
    db: Session,
    *,
    organization_id: int,
    days_back: int = 3,
) -> list[Notification]:
    today = date.today()
    since = today - timedelta(days=days_back)
    project_ids = (
        db.query(Project.id).filter(Project.organization_id == organization_id).all()
    )
    project_ids = [p[0] for p in project_ids]

    register_ids = (
        db.query(Register.id).filter(
            Register.organization_id == organization_id,
            Register.is_active == True,
        )
    ).all()
    register_ids = [r[0] for r in register_ids]

    notifications: list[Notification] = []

    for pid in project_ids:
        existing_dates = set(
            db.query(Report.report_date)
            .filter(
                Report.project_id == pid,
                Report.report_date >= since,
            )
            .distinct()
            .all()
        )
        existing_dates = {d[0] for d in existing_dates}

        for day_offset in range(days_back + 1):
            check_date = today - timedelta(days=day_offset)
            if check_date in existing_dates:
                continue

            if check_date.weekday() >= 5:
                continue

            assigned_users = (
                db.query(ProjectAssignment.user_id)
                .filter(ProjectAssignment.project_id == pid)
                .all()
            )
            for (uid,) in assigned_users:
                existing = (
                    db.query(Notification)
                    .filter(
                        Notification.user_id == uid,
                        Notification.type == "missed_form",
                        Notification.link == f"/projects/{pid}?date={check_date}",
                    )
                    .first()
                )
                if existing:
                    continue

                n = Notification(
                    organization_id=organization_id,
                    user_id=uid,
                    type="missed_form",
                    title="Missing daily report",
                    body=f"No report submitted for {check_date.isoformat()} on project #{pid}.",
                    link=f"/projects/{pid}?date={check_date}",
                    is_read=False,
                )
                db.add(n)
                notifications.append(n)

    if notifications:
        db.commit()

    return notifications
