import logging

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Project, Report
from app.repositories.base import BaseRepository
from app.schemas import ReportCreate, ReportRead

logger = logging.getLogger(__name__)


def create_report(db: Session, payload: ReportCreate) -> ReportRead:
    project = db.get(Project, payload.project_id)
    if project is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found.",
        )
    repo = BaseRepository(db, Report)
    data = payload.model_dump()
    data["organization_id"] = project.organization_id
    report = repo.create(**data)
    db.commit()
    db.refresh(report)
    logger.info("Created report %s for project %s", report.id, report.project_id)
    return ReportRead.model_validate(report)


def list_reports(
    db: Session,
    *,
    project_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[ReportRead]:
    filters = {}
    if project_id is not None:
        filters["project_id"] = project_id
    repo = BaseRepository(db, Report)
    reports = repo.list(
        skip=skip,
        limit=limit,
        filters=filters,
        sort_by="report_date",
        sort_order="desc",
    )
    return [ReportRead.model_validate(r) for r in reports]


def get_report(db: Session, report_id: int) -> ReportRead:
    repo = BaseRepository(db, Report)
    report = repo.get_or_404(report_id)
    return ReportRead.model_validate(report)
