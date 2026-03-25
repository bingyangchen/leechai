from datetime import datetime

from main.core.schema.base import BaseDataModel


class EntryChange(BaseDataModel):
    id: str
    type: str
    debit_account_id: str
    credit_account_id: str
    amount: float
    memo: str | None
    occurred_at: datetime
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class AccountChange(BaseDataModel):
    id: str
    type: str
    sub_type: str
    name: str | None
    icon: str | None
    initial_balance: float
    last_used_at: datetime
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class TagChange(BaseDataModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class EntryTagChange(BaseDataModel):
    entry_id: str
    tag_id: str
    updated_at: datetime
    deleted_at: datetime | None


class AchievementChange(BaseDataModel):
    id: str
    progress: int
    target: int
    unlocked_at: datetime | None
    completed_count: int
    progress_period: str | None
    is_notified: bool
    created_at: datetime
    updated_at: datetime


class BudgetChange(BaseDataModel):
    id: str
    year: int
    month: int
    total_amount: float
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class CategoryBudgetChange(BaseDataModel):
    id: str
    year: int
    month: int
    account_id: str
    amount: float
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class Changes(BaseDataModel):
    entry: list[EntryChange] = []
    account: list[AccountChange] = []
    achievement: list[AchievementChange] = []
    tag: list[TagChange] = []
    entry_tag: list[EntryTagChange] = []
    budget: list[BudgetChange] = []
    category_budget: list[CategoryBudgetChange] = []
