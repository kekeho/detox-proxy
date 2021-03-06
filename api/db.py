# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.ext.declarative.api import DeclarativeMeta
from sqlalchemy import Column, Integer, String, Boolean

import os
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


class Block(Base):
    __tablename__ = 'block'
    id = Column('id', Integer, primary_key=True)
    url = Column('url', String, nullable=False)
    start = Column('start', Integer, nullable=False)  # sec
    end = Column('end', Integer, nullable=False)  # sec
    active = Column('active', Boolean, nullable=False, default=True)
