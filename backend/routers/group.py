from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/groups",
    tags=["Groups"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.Group, status_code=status.HTTP_201_CREATED)
def create_group(
    group: schemas.GroupCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new group. The creator is automatically added as an admin.
    """
    new_group = models.Group(name=group.name, created_by_id=current_user.id)
    db.add(new_group)
    db.flush() # Use flush to get the new_group.id before committing

    # Add the creator as the first member with the 'admin' role
    first_member = models.GroupMember(
        group_id=new_group.id, 
        user_id=current_user.id, 
        role="admin"
    )
    db.add(first_member)
    db.commit()
    db.refresh(new_group)
    return new_group

@router.get("/", response_model=List[schemas.Group])
def get_user_groups(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get a list of all groups the current user is a member of.
    """
    user_memberships = db.query(models.GroupMember).filter(models.GroupMember.user_id == current_user.id).all()
    groups = [membership.group for membership in user_memberships]
    return groups

@router.post("/{group_id}/members", response_model=schemas.GroupMember, status_code=status.HTTP_201_CREATED)
def add_group_member(
    group_id: int,
    member_to_add: schemas.GroupMemberAdd,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Add a new member to a group. Only admins can add members.
    """
    # Check if the current user is an admin of the group
    admin_membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id,
        models.GroupMember.role == "admin"
    ).first()

    if not admin_membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to add members to this group."
        )

    # Find the user to add
    user_to_add = db.query(models.User).filter(models.User.email == member_to_add.user_email).first()
    if not user_to_add:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User to add not found.")

    # Check if the user is already a member
    existing_membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == user_to_add.id
    ).first()
    if existing_membership:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a member of this group."
        )

    new_member = models.GroupMember(group_id=group_id, user_id=user_to_add.id, role="member")
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    return new_member
