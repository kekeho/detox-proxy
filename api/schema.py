# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from pydantic import BaseModel
from typing import List

import db


class Block(BaseModel):
    id: int
    url: str
    start: int
    end: int
    active: bool

    @classmethod
    def from_db(cls, db_block: db.Block):
        return cls(
            id=db_block.id,
            url=db_block.url,
            start=db_block.start,
            end=db_block.end,
            active=db_block.active,
        )


class User(BaseModel):
    id: int
    username: str
    email: str
    blocklist: List[Block]

    @classmethod
    def from_db(cls, db_user: db.User):
        return cls(
            id=db_user.id,
            username=db_user.username,
            email=db_user.email,
            blocklist=[Block.from_db(b) for b in db_user.blocklist]
        )


class CreateUser(BaseModel):
    username: str
    email: str
    raw_password: str

    def create(self) -> User:
        with db.session_scope() as s:
            exists = db.User.get_with_email(s, self.email)
            if exists is not None:
                raise HTTPException(status.HTTP_409_CONFLICT,
                                    'Email already registered')

            u = db.User.create(self.username, self.email,
                               self.raw_password)
            s.add(u)
            s.commit()

            return User.from_db(u)
