from fastapi import APIRouter, Depends, status

from app.auth.dependencies import get_current_user
from app.dependencies import DbSession
from app.models import User
from app.services.remark_service import list_remarks, create_remark

router = APIRouter(
    prefix="/remarks",
    tags=["remarks"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/{report_id}")
def get_remarks(report_id: int, db: DbSession, current_user: User = Depends(get_current_user)):
    return list_remarks(db, report_id=report_id, current_user=current_user)


@router.post("", status_code=status.HTTP_201_CREATED)
def post_remark(
    report_id: int,
    content: str,
    db: DbSession,
    current_user: User = Depends(get_current_user),
    is_admin_only: bool = False,
):
    return create_remark(
        db,
        report_id=report_id,
        content=content,
        is_admin_only=is_admin_only,
        current_user=current_user,
    )
