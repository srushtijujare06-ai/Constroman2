from fastapi import APIRouter, Depends, Query

from app.auth.dependencies import get_current_user, require_admin
from app.dependencies import DbSession
from app.models import User
from app.services.reminder_service import check_missed_forms

router = APIRouter(
    prefix="/reminders",
    tags=["reminders"],
    dependencies=[Depends(get_current_user)],
)


@router.post("/check-missed")
def run_missed_check(
    db: DbSession,
    days_back: int = Query(default=3, ge=1, le=14),
    current_user: User = Depends(require_admin),
):
    notifications = check_missed_forms(
        db,
        organization_id=current_user.organization_id,
        days_back=days_back,
    )
    return {"missed_found": len(notifications)}
