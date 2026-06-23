from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import Project, User
from app.repositories.project_repo import ProjectRepository
from app.schemas import ProjectRead, SubprojectRead


def list_projects(
    db: Session,
    *,
    current_user: User | None = None,
    organization_id: int | None = None,
    status: str | None = None,
    skip: int = 0,
    limit: int = 100,
) -> list[ProjectRead]:
    repo = ProjectRepository(db)

    assigned_ids: list[int] | None = None
    if current_user and current_user.role == "employee":
        assigned_ids = [a.project_id for a in current_user.assignments]

    projects = repo.list_with_subprojects(
        organization_id=organization_id,
        status=status,
        skip=skip,
        limit=limit,
        assigned_ids=assigned_ids,
    )
    result = []
    for p in projects:
        project_read = ProjectRead.model_validate(p)
        result.append(project_read)
    return result


def get_project(db: Session, project_id: int, current_user: User | None = None) -> ProjectRead:
    repo = ProjectRepository(db)
    project = repo.get_with_subprojects(project_id)
    if project is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found.",
        )
    if current_user and current_user.role == "employee":
        assigned_ids = {a.project_id for a in current_user.assignments}
        if project_id not in assigned_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not assigned to this project.",
            )
    return ProjectRead.model_validate(project)
