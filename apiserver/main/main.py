import logging
import logging.config

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from main.config import settings

logger = logging.getLogger(__name__)


def setup_logging() -> None:
    logging.config.dictConfig(
        {
            "version": 1,
            "formatters": {
                "default": {
                    "format": "[%(levelname)s]%(asctime)s - %(name)s:%(lineno)d\n%(message)s"  # noqa: E501
                },
            },
            "handlers": {
                "default": {"class": "logging.StreamHandler", "formatter": "default"},
            },
            "root": {"level": settings.LOG_LEVEL, "handlers": ["default"]},
        }
    )


app = FastAPI(title="Leechai API Server")


@app.exception_handler(Exception)
async def unexpected_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    logger.error(f"Unexpected error: {exc}")
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


@app.get("/")
def root():
    return {"message": "ok"}


@app.get("/health")
def health():
    return {"status": "ok"}
