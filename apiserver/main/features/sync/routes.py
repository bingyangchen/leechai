import logging

from fastapi import APIRouter

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/pull")
async def pull():
    pass


@router.post("/push")
async def push():
    pass
