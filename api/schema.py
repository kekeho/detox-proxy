# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from pydantic import BaseModel
from fastapi import HTTPException, status
from typing import List
import os
import requests

from sqlalchemy.orm.scoping import scoped_session
import db


HOST = os.environ['DETOX_PROXY_PROXY_HOST']
PROXY_API_PORT = os.environ['DETOX_PROXY_PROXY_API_PORT']


def send_blocks(blocks: List['Block']):
    block_list = []
    for b in blocks:
        block_dict = {
            'url': b.url,
            'start': b.start,
            'end': b.end,
            'active': b.active,
        }
        block_list.append(block_dict)

    r = requests.post(f'http://proxy:{PROXY_API_PORT}/block/regist',
                      json=block_list)
    if r.status_code != 201:
        raise Exception()


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

    def create(self, s: scoped_session) -> Block:
        b = db.Block()
        b.url = self.url
        b.start = self.start
        b.end = self.end
        b.active = self.active

        s.add(b)
        s.commit()

        return Block.from_db(b)


# SYNC

def sync_block():
    blocks = []
    with db.session_scope() as s:
        db_blocks = s.query(db.Block).all()
        for b in db_blocks:
            blocks.append(Block.from_db(b))

    send_blocks(blocks)
