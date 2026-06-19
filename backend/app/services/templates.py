from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import FormCategory, FormTemplate


def list_templates_by_category(db: Session, category_id: int) -> list[FormTemplate]:
    category = db.get(FormCategory, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found.")

    stmt = (
        select(FormTemplate)
        .where(FormTemplate.category_id == category_id, FormTemplate.is_active.is_(True))
        .order_by(FormTemplate.version.desc(), FormTemplate.name)
    )
    return list(db.scalars(stmt).all())
