from sqlalchemy import or_, select, func, text
from sqlalchemy.orm import Session

from app.models import Submission
from app.repositories.base import BaseRepository


class SubmissionRepository(BaseRepository[Submission]):
    def __init__(self, db: Session) -> None:
        super().__init__(db, Submission)

    def search(
        self,
        *,
        organization_id: int,
        project_id: int | None = None,
        register_id: int | None = None,
        status: str | None = None,
        search: str | None = None,
        skip: int = 0,
        limit: int = 100,
        sort_by: str = "created_at",
        sort_order: str = "desc",
    ) -> list[Submission]:
        stmt = select(Submission).where(
            Submission.organization_id == organization_id
        )
        if project_id is not None:
            stmt = stmt.where(Submission.project_id == project_id)
        if register_id is not None:
            stmt = stmt.where(Submission.register_id == register_id)
        if status is not None:
            stmt = stmt.where(Submission.status == status)
        if search:
            search_filter = or_(
                Submission.form_data["material_name"].astext.ilike(f"%{search}%"),
                Submission.title.ilike(f"%{search}%"),
                Submission.form_data.cast(text("text")).ilike(f"%{search}%"),
            )
            stmt = stmt.where(search_filter)
        sort_col = getattr(Submission, sort_by, Submission.created_at)
        if sort_order == "desc":
            stmt = stmt.order_by(sort_col.desc(), Submission.id.desc())
        else:
            stmt = stmt.order_by(sort_col.asc(), Submission.id.asc())
        stmt = stmt.offset(skip).limit(limit)
        return list(self.db.scalars(stmt).all())

    def count_filtered(
        self,
        *,
        organization_id: int,
        project_id: int | None = None,
        register_id: int | None = None,
        status: str | None = None,
        search: str | None = None,
    ) -> int:
        stmt = select(func.count(Submission.id)).where(
            Submission.organization_id == organization_id
        )
        if project_id is not None:
            stmt = stmt.where(Submission.project_id == project_id)
        if register_id is not None:
            stmt = stmt.where(Submission.register_id == register_id)
        if status is not None:
            stmt = stmt.where(Submission.status == status)
        if search:
            search_filter = or_(
                Submission.form_data["material_name"].astext.ilike(f"%{search}%"),
                Submission.title.ilike(f"%{search}%"),
                Submission.form_data.cast(text("text")).ilike(f"%{search}%"),
            )
            stmt = stmt.where(search_filter)
        return self.db.scalar(stmt) or 0
