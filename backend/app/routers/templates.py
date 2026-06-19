from fastapi import APIRouter

from app.dependencies import DbSession
from app.schemas import FormTemplateRead
from app.services.template_service import list_templates_by_register

router = APIRouter(prefix="/templates", tags=["templates"])


@router.get("/{register_id}", response_model=list[FormTemplateRead])
def get_templates(register_id: int, db: DbSession) -> list[FormTemplateRead]:
    return list_templates_by_register(db, register_id)
