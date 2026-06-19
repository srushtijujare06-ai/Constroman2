from sqlalchemy.orm import Session

from app.models import Attachment
from app.repositories.base import BaseRepository
from app.schemas import AttachmentCreate, AttachmentRead


def create_attachment(
    db: Session, organization_id: int, payload: AttachmentCreate
) -> AttachmentRead:
    repo = BaseRepository(db, Attachment)
    attachment = repo.create(organization_id=organization_id, **payload.model_dump())
    db.commit()
    db.refresh(attachment)
    return AttachmentRead.model_validate(attachment)


def list_attachments(
    db: Session,
    organization_id: int,
    *,
    submission_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[AttachmentRead]:
    filters = {"organization_id": organization_id}
    if submission_id is not None:
        filters["submission_id"] = submission_id
    repo = BaseRepository(db, Attachment)
    attachments = repo.list(skip=skip, limit=limit, filters=filters, sort_by="created_at", sort_order="desc")
    return [AttachmentRead.model_validate(a) for a in attachments]
