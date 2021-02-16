# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from pydantic import BaseModel
from fastapi import HTTPException, status
from typing import List, Optional

from pydantic.networks import EmailStr
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig

import os
import db


email_config = ConnectionConfig(
    MAIL_USERNAME=os.environ['MAIL_USERNAME'],
    MAIL_PASSWORD=os.environ['MAIL_PASSWORD'],
    MAIL_FROM=os.environ['MAIL_FROM'],
    MAIL_PORT=int(os.environ['MAIL_PORT']),
    MAIL_SERVER=os.environ['MAIL_SERVER'],
    MAIL_TLS=True,
    MAIL_SSL=False,
    USE_CREDENTIALS=True,
)

fm = FastMail(email_config)


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

    async def send_mail(self, subj: str, message: str):
        msg = MessageSchema(
            subject=subj,
            recipients=[self.email],
            body=message,
        )

        await fm.send_message(msg)


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


class LoginUser(BaseModel):
    email: str
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
            u: Optional[db.User] = db.User.get_with_email(s, self.email)
            if u is None:
                return None

            if not u.login(self.raw_password):
                return None

            return db.Token.issue_token(u)
