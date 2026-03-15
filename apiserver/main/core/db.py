from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from main.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.SQL_LOG,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=20,
)

async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False, autobegin=False
)


async def get_session():
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()
