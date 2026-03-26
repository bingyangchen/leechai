"""category_budget: sub_type -> account_id

Revision ID: c8f4e2b91a3d
Revises: 091c1bc3cca3
Create Date: 2026-03-25 12:00:00+00:00

Renames column sub_type -> account_id, then replaces label values with expense
account ids. Does not add a second column.

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "c8f4e2b91a3d"
down_revision: str | Sequence[str] | None = "091c1bc3cca3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    for unique in inspector.get_unique_constraints("category_budget"):
        if set(unique["column_names"]) == {"user_id", "year", "month", "sub_type"}:
            op.drop_constraint(unique["name"], "category_budget", type_="unique")
            break
    else:
        raise RuntimeError(
            "Expected UNIQUE (user_id, year, month, sub_type) on category_budget"
        )

    op.alter_column(
        "category_budget",
        "sub_type",
        new_column_name="account_id",
        existing_type=sa.String(length=255),
        existing_nullable=False,
    )

    op.execute(
        sa.text("""
            UPDATE category_budget AS cb
            SET account_id = (
                SELECT a.id
                FROM account AS a
                WHERE a.user_id = cb.user_id
                  AND a.type = 'expense'
                  AND a.sub_type = cb.account_id
                ORDER BY CASE WHEN a.deleted_at IS NULL THEN 0 ELSE 1 END,
                         a.updated_at DESC NULLS LAST
                LIMIT 1
            )
        """)
    )
    op.execute(
        sa.text("""
            DELETE FROM category_budget AS cb
            WHERE NOT EXISTS (
                SELECT 1
                FROM account AS a
                WHERE a.user_id = cb.user_id AND a.id = cb.account_id
            )
        """)
    )
    op.alter_column(
        "category_budget",
        "account_id",
        existing_type=sa.String(length=255),
        type_=sa.String(length=36),
        existing_nullable=False,
        nullable=False,
    )
    op.create_unique_constraint(
        "category_budget_user_id_year_month_account_id_key",
        "category_budget",
        ["user_id", "year", "month", "account_id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "category_budget_user_id_year_month_account_id_key",
        "category_budget",
        type_="unique",
    )
    op.alter_column(
        "category_budget",
        "account_id",
        existing_type=sa.String(length=36),
        type_=sa.String(length=255),
        existing_nullable=False,
        nullable=False,
    )
    op.alter_column(
        "category_budget",
        "account_id",
        new_column_name="sub_type",
        existing_type=sa.String(length=255),
        existing_nullable=False,
    )
    op.execute(
        sa.text("""
            UPDATE category_budget AS cb
            SET sub_type = (
                SELECT a.sub_type
                FROM account AS a
                WHERE a.user_id = cb.user_id AND a.id = cb.sub_type
                LIMIT 1
            )
        """)
    )
    op.execute(
        sa.text("""
            DELETE FROM category_budget AS cb
            WHERE NOT EXISTS (
                SELECT 1
                FROM account AS a
                WHERE a.user_id = cb.user_id
                  AND a.type = 'expense'
                  AND a.sub_type = cb.sub_type
            )
        """)
    )
    op.create_unique_constraint(
        "category_budget_user_id_year_month_sub_type_key",
        "category_budget",
        ["user_id", "year", "month", "sub_type"],
    )
