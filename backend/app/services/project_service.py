from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import Project
from app.repositories.project_repo import ProjectRepository
from app.schemas import ProjectRead, SubprojectRead


def list_projects(
    db: Session,
    *,
    organization_id: int | None = None,
    status: str | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[ProjectRead]:
    repo = ProjectRepository(db)
    projects = repo.list_with_subprojects(
        organization_id=organization_id,
        status=status,
        skip=skip,
        limit=limit,
    )
    result = []
    for p in projects:
        project_read = ProjectRead.model_validate(p)
        result.append(project_read)
    return result


def get_project(db: Session, project_id: int) -> ProjectRead:
    repo = ProjectRepository(db)
    project = repo.get_with_subprojects(project_id)
    if project is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found.",
        )
    return ProjectRead.model_validate(project)
