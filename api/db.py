# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from typing import Optional
from sqlalchemy.orm import sessionmaker, scoped_session, relationship
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.ext.declarative.api import DeclarativeMeta
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey

import bcrypt
import os
import uuid
from typing import Any
from contextlib import contextmanager


PG_USER = os.environ.get('POSTGRES_USER')
PG_PASSWORD = os.environ.get('POSTGRES_PASSWORD')
DB_URL = f'postgresql://{PG_USER}:{PG_PASSWORD}@apidb'
DB_ECHO = (os.environ.get('DB_ECHO') != 'False')

engine = create_engine(
    DB_URL,
    echo=DB_ECHO
)

Session = scoped_session(
    sessionmaker(
        autocommit=False, autoflush=True,
        bind=engine, expire_on_commit=False
    )
)


@contextmanager
def session_scope() -> scoped_session:
    session = Session()
    try:
        yield session
        session.commit()
    except Exception as e:
        session.rollback()
        raise e
    finally:
        session.close()


Base: DeclarativeMeta = declarative_base()


class User(Base):
    __tablename__ = 'user'
    id = Column('id', Integer, primary_key=True)
    username = Column('username', String, nullable=False)
    email = Column('email', String, nullable=False, unique=True)

    hashed_password = Column('hashed_pass', String, nullable=False)

    blocklist = relationship('Block')

    @classmethod
    def create(cls, username: str, email: str, raw_password: str):
        salt = bcrypt.gensalt(rounds=12, prefix=b'2b')
        hashed_password = bcrypt.hashpw(raw_password.encode('utf-8'), salt)

        return cls(
            username=username,
            email=email,
            hashed_password=hashed_password.decode(),
        )

    @classmethod
    def get(cls, s: scoped_session, id: int) -> Optional[Any]:
        """Get user with id

        params
        ------
            s: scoped_session
            id: user id

        returns
        -------
            user: Optional[User]
                user exists -> User
                user not found -> None
        """
        u = s.query(cls).get(id)
        if u is None:
            return None

        return u

    @classmethod
    def get_with_email(cls, s: scoped_session, email: str):
        """Get User

        return:
            user: Optional[User]
                success -> User
                not found -> None
        """
        q = s.query(cls).filter(cls.email == email).all()
        if len(q) == 0:
            return None

        return q[0]

    def login(self, raw_password: str) -> bool:
        """Login user
        Parameters
        ----------
        raw_password: str

        Return
        ------
        success: bool
        """
        hashed_password = str(self.hashed_password)
        print(hashed_password)
        print(raw_password)
        return bcrypt.checkpw(
            raw_password.encode('utf-8'),
            hashed_password.encode('utf-8'),
        )


class Token(Base):
    """[DB]User Token
    Parameters
    ----------
    hashed_token: str
        hashed with bcrypt
    user_id: int
        user id
    is_active: bool
        Set to False when key has been expired.
    """
    __tablename__ = "token"
    hashed_token = Column('token', String, primary_key=True)
    user_id = Column("user_id", ForeignKey('user.id'))
    is_active = Column('is_active', Boolean, default=True)

    @staticmethod
    def issue_token(user: User) -> str:
        token_salt = bcrypt.gensalt(rounds=4, prefix=b'2b')
        raw_token = str(uuid.uuid4()) + f'@{user.id}'
        hashed_token = bcrypt.hashpw(raw_token.encode('utf-8'), token_salt)

        with session_scope() as s:
            token = Token(
                hashed_token=hashed_token.decode(),
                user_id=user.id,
            )
            s.add(token)
            s.commit()
        # TODO: Expire token
        return raw_token

    def _check_token(self, raw_token: str) -> bool:
        hashed: str = self.hashed_token
        return bcrypt.checkpw(
            raw_token.encode('utf-8'), hashed.encode('utf-8')
        )

    @staticmethod
    def get_userid(raw_token: str) -> Optional[int]:
        """Get userif from token
        WARNING: This method not check the validity of the token
        """
        id: Optional[int] = None
        try:
            id = int(raw_token.split('@')[-1])
        except (ValueError, IndexError):
            return None

        return id

    @staticmethod
    def get_user(s: scoped_session, raw_token) -> Optional[Any]:
        """Auth

        returns
        -------
        maybe_user: Optional[User]
            User -> success
            None -> Unauthorized
        """
        userid = Token.get_userid(raw_token)
        if userid is None:
            return None

        tokens = s.query(Token).filter(
            Token.user_id == userid
        ).filter(
            Token.is_active
        )
        for token in tokens:
            if token._check_token(raw_token):
                return s.query(User).get(userid)

        return None

    def expire(self) -> None:
        with session_scope() as s:
            self.is_active = False
            s.commit()


class Block(Base):
    __tablename__ = 'block'
    id = Column('id', Integer, primary_key=True)
    user = Column('user_id', ForeignKey('user.id'), nullable=False)
    url = Column('url', String, nullable=False)
    start = Column('start', Integer, nullable=False)  # sec
    end = Column('end', Integer, nullable=False)  # sec
    active = Column('active', Boolean, nullable=False, default=True)
