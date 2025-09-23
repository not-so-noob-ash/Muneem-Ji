from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/friends",
    tags=["Friends"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/request", response_model=schemas.Friendship, status_code=status.HTTP_201_CREATED)
def send_friend_request(
    request: schemas.FriendRequestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Send a friend request to another user by their email.
    """
    recipient = db.query(models.User).filter(models.User.email == request.recipient_email).first()

    if not recipient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recipient user not found.")
    
    if recipient.id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot send a friend request to yourself.")

    # Check if a friendship/request already exists between these users
    existing_friendship = db.query(models.Friendship).filter(
        or_(
            (models.Friendship.user_one_id == current_user.id) & (models.Friendship.user_two_id == recipient.id),
            (models.Friendship.user_one_id == recipient.id) & (models.Friendship.user_two_id == current_user.id)
        )
    ).first()
    
    if existing_friendship:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A friend request or friendship already exists.")

    new_request = models.Friendship(user_one_id=current_user.id, user_two_id=recipient.id, status="pending")
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/requests/pending", response_model=List[schemas.Friendship])
def get_pending_requests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get a list of all pending friend requests received by the user.
    """
    pending_requests = db.query(models.Friendship).filter(
        models.Friendship.user_two_id == current_user.id,
        models.Friendship.status == "pending"
    ).all()
    return pending_requests

@router.put("/request/{friendship_id}/accept", response_model=schemas.Friendship)
def accept_friend_request(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Accept a pending friend request.
    """
    friend_request = db.query(models.Friendship).filter(
        models.Friendship.id == friendship_id,
        models.Friendship.user_two_id == current_user.id,
        models.Friendship.status == "pending"
    ).first()

    if not friend_request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pending friend request not found.")
    
    friend_request.status = "accepted"
    db.commit()
    db.refresh(friend_request)
    return friend_request

@router.delete("/request/{friendship_id}/decline", status_code=status.HTTP_204_NO_CONTENT)
def decline_friend_request(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Decline or cancel a friend request.
    """
    friend_request = db.query(models.Friendship).filter(
        models.Friendship.id == friendship_id,
        # User can decline if they are the recipient OR cancel if they are the sender
        or_(
            models.Friendship.user_two_id == current_user.id,
            models.Friendship.user_one_id == current_user.id
        )
    ).first()
    
    if not friend_request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found.")

    db.delete(friend_request)
    db.commit()
    return

@router.get("/", response_model=List[schemas.FriendUser])
def get_friends(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get a list of all accepted friends for the current user.
    """
    friendships = db.query(models.Friendship).filter(
        or_(
            models.Friendship.user_one_id == current_user.id,
            models.Friendship.user_two_id == current_user.id
        ),
        models.Friendship.status == "accepted"
    ).all()

    friends = []
    for friendship in friendships:
        if friendship.user_one_id == current_user.id:
            friends.append(friendship.recipient)
        else:
            friends.append(friendship.requester)
    
    return friends
