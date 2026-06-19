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
    filters = {"is_active": True}
    if organization_id is not None:
        filters["organization_id"] = organization_id
    repo = BaseRepository(db, Register)
    registers = repo.list(
        skip=skip,
        limit=limit,
        filters=filters,
        sort_by="sort_order",
        sort_order="asc",
    )
    return [RegisterRead.model_validate(r) for r in registers]


def get_register(db: Session, register_id: int) -> RegisterRead:
    repo = BaseRepository(db, Register)
    register = repo.get_or_404(register_id)
    return RegisterRead.model_validate(register)
