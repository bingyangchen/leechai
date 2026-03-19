from pydantic import BaseModel, ConfigDict


class BaseDataModel(BaseModel):
    model_config = ConfigDict(
        validate_by_name=True, validate_by_alias=True, from_attributes=True
    )
