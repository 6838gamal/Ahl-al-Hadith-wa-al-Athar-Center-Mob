from __future__ import annotations
from datetime import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, field_validator
import uuid


# ─── Auth ─────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    display_name: str
    password: str
    academic_id: str
    role: str  # 'male_student' | 'female_student' | 'sheikh'
    email: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class RegisterResponse(BaseModel):
    success: bool = True
    pending: bool
    message: str

class AdminLoginRequest(BaseModel):
    username: str
    password: str


# ─── Users ────────────────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    id: str
    username: str
    display_name: Optional[str]
    email: Optional[str]
    academic_id: str
    role: str
    status: str
    gender: str
    avatar_url: Optional[str]
    bio: Optional[str]
    is_online: bool
    last_seen: Optional[datetime]
    created_at: datetime

class UserUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    email: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

class AdminUserUpdateRequest(BaseModel):
    status: Optional[str] = None
    role: Optional[str] = None


# ─── Conversations & Messages ─────────────────────────────────────────────────

class ConversationResponse(BaseModel):
    id: str
    type: str
    title: Optional[str]
    avatar_url: Optional[str]
    description: Optional[str]
    unread_count: int
    last_message: Optional[MessageResponse]
    participants: List[UserResponse]
    created_at: datetime
    updated_at: datetime

class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    sender: Optional[UserResponse]
    content: Optional[str]
    type: str
    status: str
    media_url: Optional[str]
    reply_to_id: Optional[str]
    reply_to: Optional[MessageResponse] = None
    reactions: List[ReactionResponse] = []
    mentioned_user_ids: List[str] = []
    is_deleted: bool
    edited_at: Optional[datetime]
    created_at: datetime

class SendMessageRequest(BaseModel):
    content: Optional[str] = None
    type: str = "text"
    reply_to_id: Optional[str] = None
    mentioned_user_ids: List[str] = []

class CreateConversationRequest(BaseModel):
    participant_id: str

class ReactionResponse(BaseModel):
    id: str
    message_id: str
    user_id: str
    emoji: str
    created_at: datetime

class AddReactionRequest(BaseModel):
    emoji: str


# ─── Groups ───────────────────────────────────────────────────────────────────

class GroupResponse(BaseModel):
    id: str
    conversation_id: Optional[str]
    name: str
    description: Optional[str]
    avatar_url: Optional[str]
    is_private: bool
    gender_filter: Optional[str]
    max_members: int
    member_count: int
    created_by: Optional[str]
    created_at: datetime

class CreateGroupRequest(BaseModel):
    name: str
    description: Optional[str] = None
    is_private: bool = False
    gender_filter: Optional[str] = None
    max_members: int = 500


# ─── Tickets ──────────────────────────────────────────────────────────────────

class TicketResponse(BaseModel):
    id: str
    title: str
    body: str
    submitter_id: str
    submitter: Optional[UserResponse]
    assignee_id: Optional[str]
    assignee: Optional[UserResponse]
    status: str
    priority: str
    replies: List[TicketReplyResponse] = []
    resolved_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

class CreateTicketRequest(BaseModel):
    title: str
    body: str
    priority: str = "medium"

class TicketReplyResponse(BaseModel):
    id: str
    ticket_id: str
    author_id: str
    author: Optional[UserResponse]
    content: str
    is_internal: bool
    created_at: datetime

class AddTicketReplyRequest(BaseModel):
    content: str
    is_internal: bool = False

class UpdateTicketRequest(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    assignee_id: Optional[str] = None


# ─── Notifications ────────────────────────────────────────────────────────────

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    body: str
    is_read: bool
    action_url: Optional[str]
    metadata: Optional[Any]
    created_at: datetime


# ─── Courses ──────────────────────────────────────────────────────────────────

class CourseResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    thumbnail_url: Optional[str]
    instructor_id: str
    instructor: Optional[UserResponse]
    status: str
    gender_filter: Optional[str]
    start_date: Optional[Any]
    end_date: Optional[Any]
    enrolled: bool = False
    progress: int = 0
    created_at: datetime

class CreateCourseRequest(BaseModel):
    title: str
    description: Optional[str] = None
    thumbnail_url: Optional[str] = None
    status: str = "draft"
    gender_filter: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None


# ─── Admin ────────────────────────────────────────────────────────────────────

class DashboardStats(BaseModel):
    total_users: int
    active_users: int
    pending_users: int
    total_messages: int
    total_tickets: int
    open_tickets: int
    total_groups: int
    total_courses: int

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    per_page: int
    pages: int
