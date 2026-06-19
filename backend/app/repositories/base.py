from typing import Any, Generic, TypeVar

from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from app.database import Base

ModelT = TypeVar("ModelT", bound=Base)


class BaseRepository(Generic[ModelT]):
    def __init__(self, db: Session, model: type[ModelT]) -> None:
        self.db = db
        self.model = model

    def create(self, **kwargs: Any) -> ModelT:
        instance = self.model(**kwargs)
        self.db.add(instance)
        self.db.flush()
        return instance

    def get(self, id: int) -> ModelT | None:
        return self.db.get(self.model, id)

    def get_or_404(self, id: int) -> ModelT:
        instance = self.get(id)
        if instance is None:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"{self.model.__name__} not found.",
            )
        return instance

    def list(
        self,
        *,
        skip: int = 0,
        limit: int = 100,
        filters: dict[str, Any] | None = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
    ) -> list[ModelT]:
        stmt = select(self.model)
        if filters:
            for key, value in filters.items():
                if value is not None:
                    stmt = stmt.where(getattr(self.model, key) == value)
        sort_col = getattr(self.model, sort_by, None)
        if sort_col is not None:
            stmt = stmt.order_by(sort_col.desc() if sort_order == "desc" else sort_col.asc())
        stmt = stmt.offset(skip).limit(limit)
        return list(self.db.scalars(stmt).all())

    def count(self, filters: dict[str, Any] | None = None) -> int:
        stmt = select(func.count(self.model.id))
        if filters:
            for key, value in filters.items():
                if value is not None:
                    stmt = stmt.where(getattr(self.model, key) == value)
        return self.db.scalar(stmt) or 0

    def update(self, instance: ModelT, **kwargs: Any) -> ModelT:
        for key, value in kwargs.items():
            if value is not None:
                setattr(instance, key, value)
        self.db.flush()
        return instance

    def delete(self, instance: ModelT) -> None:
        self.db.delete(instance)
        self.db.flush()
