import logging

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import FormCategory, FormSubmission, FormTemplate, Report
from app.schemas import FormSubmissionCreate

logger = logging.getLogger(__name__)


def create_submission(db: Session, payload: FormSubmissionCreate) -> FormSubmission:
    if db.get(Report, payload.report_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")
    if db.get(FormCategory, payload.category_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found.")

    template_id = payload.template_id
    if template_id is None:
        template_id = _latest_active_template_id(db, payload.category_id)
    elif db.get(FormTemplate, template_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found.")

    submission = FormSubmission(
        report_id=payload.report_id,
        category_id=payload.category_id,
        template_id=template_id,
        submitted_by_id=payload.submitted_by_id,
        form_data=payload.form_data,
    )
    db.add(submission)
    db.commit()
    db.refresh(submission)
    logger.info("Created form submission %s for report %s", submission.id, submission.report_id)
    return submission


def list_submissions_by_report(db: Session, report_id: int) -> list[FormSubmission]:
    if db.get(Report, report_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

    stmt = (
        select(FormSubmission)
        .where(FormSubmission.report_id == report_id)
        .order_by(FormSubmission.created_at.desc(), FormSubmission.id.desc())
    )
    return list(db.scalars(stmt).all())


def _latest_active_template_id(db: Session, category_id: int) -> int | None:
    stmt = (
        select(FormTemplate.id)
        .where(FormTemplate.category_id == category_id, FormTemplate.is_active.is_(True))
        .order_by(FormTemplate.version.desc(), FormTemplate.id.desc())
        .limit(1)
    )
    return db.scalar(stmt)
