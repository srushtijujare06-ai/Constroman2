from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import AdminRemark, User


def list_remarks(
    db: Session,
    *,
    report_id: int,
    current_user: User,
) -> list[AdminRemark]:
    q = db.query(AdminRemark).filter(AdminRemark.report_id == report_id)
    if current_user.role == "employee":
        q = q.filter(AdminRemark.is_admin_only == False)
    return q.order_by(AdminRemark.created_at.desc()).all()


def create_remark(
    db: Session,
    *,
    report_id: int,
    content: str,
    is_admin_only: bool,
    current_user: User,
) -> AdminRemark:
    if is_admin_only and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create admin-only remarks.",
        )
    remark = AdminRemark(
        organization_id=current_user.organization_id,
        report_id=report_id,
        user_id=current_user.id,
        remark_text=content,
        is_admin_only=is_admin_only,
        remark_scope="admin" if is_admin_only else "general",
    )
    db.add(remark)
    db.commit()
    db.refresh(remark)
    return remark
