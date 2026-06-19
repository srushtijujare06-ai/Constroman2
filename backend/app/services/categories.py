from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import FormCategory


def list_categories(db: Session) -> list[FormCategory]:
    stmt = (
        select(FormCategory)
        .where(FormCategory.is_active.is_(True))
        .order_by(FormCategory.sort_order, FormCategory.name)
    )
    return list(db.scalars(stmt).all())
