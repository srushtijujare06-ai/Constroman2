from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.dependencies import DbSession
from app.models import User
from app.schemas import RegisterRead
from app.services.register_service import list_registers, get_register

router = APIRouter(
    prefix="/registers",
    tags=["registers"],
    dependencies=[Depends(get_current_user)],
)


@router.get("", response_model=list[RegisterRead])
def get_registers(db: DbSession, current_user: User = Depends(get_current_user)) -> list[RegisterRead]:
    return list_registers(db, organization_id=current_user.organization_id)


@router.get("/{id}", response_model=RegisterRead)
def get_register_by_id(id: int, db: DbSession) -> RegisterRead:
    return get_register(db, id)
