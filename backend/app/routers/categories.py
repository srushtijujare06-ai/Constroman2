from fastapi import APIRouter

from app.dependencies import DbSession
from app.schemas import FormCategoryRead
from app.services.categories import list_categories

router = APIRouter(tags=["categories"])


@router.get("/categories", response_model=list[FormCategoryRead])
def get_categories(db: DbSession) -> list[FormCategoryRead]:
    return list_categories(db)
