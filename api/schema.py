# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from pydantic import BaseModel
from fastapi import HTTPException, status
from typing import List, Optional, Tuple
import os

from sqlalchemy.orm.scoping import scoped_session
import db

import requests


HOST = os.environ['DETOX_PROXY_PROXY_HOST']
PROXY_API_PORT = os.environ['DETOX_PROXY_PROXY_API_PORT']


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

    def update(self):
        with db.session_scope() as s:
            b = s.query(db.Block).get(self.id)
            if b is None:
                raise HTTPException(status.HTTP_404_NOT_FOUND)
            b.url = self.url
            b.start = self.start
            b.end = self.end
            b.active = self.active
            s.commit()

            return self.from_db(b)


class BlockCreate(BaseModel):
    url: str
    start: int
    end: int
    active: bool

    def create(self, s: scoped_session,
               db_user: db.User) -> Block:
        b = db.Block()
        b.user = db_user.id
        b.url = self.url
        b.start = self.start
        b.end = self.end
        b.active = self.active

        s.add(b)
        s.commit()

        return Block.from_db(b)


class User(BaseModel):
    id: int
    username: str
    blocklist: List[Block]

    @classmethod
    def from_db(cls, db_user: db.User):
        return cls(
            id=db_user.id,
            username=db_user.username,
            blocklist=[Block.from_db(b) for b in db_user.blocklist]
        )


class CreateUser(BaseModel):
    username: str
    raw_password: str

    async def create(self) -> Tuple[User, str]:
        """Create User
        WARNING: THIS METHOD DOES NOT COMMIT
        """
        with db.session_scope() as s:
            exists = db.User.get_with_username(s, self.username)
            if exists is not None:
                raise HTTPException(status.HTTP_409_CONFLICT,
                                    'Username already registered')

            db_u = db.User.create(self.username, self.raw_password)
            s.add(db_u)

            r = requests.post(f'http://proxy:{PROXY_API_PORT}/user/regist',
                              json={'username': db_u.username,
                                    'hashed_password': db_u.hashed_password})
            if r.status_code != 201:
                raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR)

            s.commit()

            u = User.from_db(db_u)
            token = db.Token.issue_token(db_u)

            return u, token


class LoginUser(BaseModel):
    username: str
    raw_password: str
    remember: bool

    def login(self) -> Optional[str]:
        """Login

        returns:
            token: Optional[str]
                success -> str
                fail -> None
        """
        with db.session_scope() as s:
            u: Optional[db.User] = db.User.get_with_username(s, self.username)
            if u is None:
                return None

            if not u.login(self.raw_password):
                return None

            return db.Token.issue_token(u)
