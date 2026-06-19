from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import AuditLog
from app.schemas import AuditLogRead


def list_audit_logs(
    db: Session,
    organization_id: int,
    *,
    entity_type: str | None = None,
    entity_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[AuditLogRead]:
    stmt = (
        select(AuditLog)
        .where(AuditLog.organization_id == organization_id)
        .order_by(AuditLog.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    if entity_type is not None:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
    if entity_id is not None:
        stmt = stmt.where(AuditLog.entity_id == entity_id)
    logs = list(db.scalars(stmt).all())
    return [AuditLogRead.model_validate(log) for log in logs]
