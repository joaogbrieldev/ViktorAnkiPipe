"""add created_at to sessions

Revision ID: 38ab3555de66
Revises: 54c7d08eb378
Create Date: 2026-05-31 12:06:03.351208

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '38ab3555de66'
down_revision: Union[str, Sequence[str], None] = '54c7d08eb378'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column("sessions", sa.Column("created_at", sa.DateTime(), nullable=True))
    op.execute(sa.text("UPDATE sessions SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL"))
    with op.batch_alter_table("sessions") as batch_op:
        batch_op.alter_column(
            "created_at",
            existing_type=sa.DateTime(),
            nullable=False,
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
        )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("sessions", "created_at")
