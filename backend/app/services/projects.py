from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models import Project


def list_projects(db: Session) -> list[Project]:
    stmt = select(Project).options(selectinload(Project.subprojects)).order_by(Project.name)
    return list(db.scalars(stmt).all())


def get_project(db: Session, project_id: int) -> Project:
    stmt = select(Project).options(selectinload(Project.subprojects)).where(Project.id == project_id)
    project = db.scalar(stmt)
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found.")
    return project
