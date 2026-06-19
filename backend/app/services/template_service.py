from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import FormTemplate
from app.schemas import FormTemplateRead


def list_templates_by_register(
    db: Session,
    register_id: int,
    *,
    only_published: bool = True,
) -> list[FormTemplateRead]:
    stmt = (
        select(FormTemplate)
        .where(FormTemplate.register_id == register_id)
        .order_by(FormTemplate.version.desc())
    )
    if only_published:
        stmt = stmt.where(FormTemplate.is_published == True)
    templates = list(db.scalars(stmt).all())
    return [FormTemplateRead.model_validate(t) for t in templates]
