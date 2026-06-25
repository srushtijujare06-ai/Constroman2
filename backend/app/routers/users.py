from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.dependencies import DbSession
from app.models import User
from app.schemas import UserRead

router = APIRouter(
    prefix="/users",
    tags=["users"],
    dependencies=[Depends(get_current_user)],
)


@router.get("", response_model=list[UserRead])
def get_users(db: DbSession, current_user: User = Depends(get_current_user)):
    users = (
        db.query(User)
        .filter(User.organization_id == current_user.organization_id)
        .all()
    )
    return [UserRead.model_validate(u) for u in users]
