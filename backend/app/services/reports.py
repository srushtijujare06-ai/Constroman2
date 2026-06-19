import logging

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Project, Report, Subproject
from app.schemas import ReportCreate

logger = logging.getLogger(__name__)


def create_report(db: Session, payload: ReportCreate) -> Report:
    if db.get(Project, payload.project_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found.")
    if payload.subproject_id is not None and db.get(Subproject, payload.subproject_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subproject not found.")

    report = Report(**payload.model_dump())
    db.add(report)
    db.commit()
    db.refresh(report)
    logger.info("Created report %s for project %s", report.id, report.project_id)
    return report


def list_reports(db: Session, project_id: int | None = None) -> list[Report]:
    stmt = select(Report).order_by(Report.report_date.desc(), Report.id.desc())
    if project_id is not None:
        stmt = stmt.where(Report.project_id == project_id)
    return list(db.scalars(stmt).all())


def get_report(db: Session, report_id: int) -> Report:
    report = db.get(Report, report_id)
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")
    return report
