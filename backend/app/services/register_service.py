from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models import Register
from app.repositories.base import BaseRepository
from app.schemas import RegisterRead


def list_registers(
    db: Session,
    *,
    organization_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[RegisterRead]:
    q = db.query(Register).filter(Register.is_active == True)
    if organization_id is not None:
        q = q.filter(
            or_(Register.organization_id == organization_id, Register.organization_id.is_(None))
        )
    q = q.order_by(Register.sort_order.asc()).offset(skip).limit(limit)
    return [RegisterRead.model_validate(r) for r in q.all()]


def get_register(db: Session, register_id: int) -> RegisterRead:
    repo = BaseRepository(db, Register)
    register = repo.get_or_404(register_id)
    return RegisterRead.model_validate(register)
