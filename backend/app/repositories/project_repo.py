from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models import Project
from app.repositories.base import BaseRepository


class ProjectRepository(BaseRepository[Project]):
    def __init__(self, db: Session) -> None:
        super().__init__(db, Project)

    def list_with_subprojects(
        self,
        *,
        skip: int = 0,
        limit: int = 100,
        organization_id: int | None = None,
        status: str | None = None,
    ) -> list[Project]:
        stmt = (
            select(Project)
            .options(selectinload(Project.subprojects))
            .order_by(Project.name)
            .offset(skip)
            .limit(limit)
        )
        if organization_id is not None:
            stmt = stmt.where(Project.organization_id == organization_id)
        if status is not None:
            stmt = stmt.where(Project.status == status)
        return list(self.db.scalars(stmt).all())

    def get_with_subprojects(self, id: int) -> Project | None:
        stmt = (
            select(Project)
            .options(selectinload(Project.subprojects))
            .where(Project.id == id)
        )
        return self.db.scalar(stmt)
