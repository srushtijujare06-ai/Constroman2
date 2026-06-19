from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import SubmissionComment, AuditLog
from app.repositories.base import BaseRepository
from app.schemas import CommentCreate, CommentRead


def create_comment(db: Session, organization_id: int, payload: CommentCreate) -> CommentRead:
    repo = BaseRepository(db, SubmissionComment)
    comment = repo.create(
        organization_id=organization_id,
        **payload.model_dump(),
    )
    db.flush()

    audit = AuditLog(
        organization_id=organization_id,
        entity_type="submission",
        entity_id=payload.submission_id,
        action="commented",
        user_id=payload.user_id,
    )
    db.add(audit)
    db.commit()
    db.refresh(comment)

    return CommentRead.model_validate(comment)


def list_comments(
    db: Session,
    organization_id: int,
    *,
    submission_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[CommentRead]:
    stmt = select(SubmissionComment).where(
        SubmissionComment.organization_id == organization_id
    )
    if submission_id is not None:
        stmt = stmt.where(SubmissionComment.submission_id == submission_id)
    stmt = stmt.order_by(SubmissionComment.created_at.asc()).offset(skip).limit(limit)
    comments = list(db.scalars(stmt).all())
    return [CommentRead.model_validate(c) for c in comments]
