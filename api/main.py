# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from typing import List
from fastapi import FastAPI, HTTPException, Response
from fastapi import status
import os

import schema
import db
import sync

# Init db
db.Base.metadata.create_all(bind=db.engine)

app = FastAPI(
    docs_url='/api/docs',
    openapi_url='/api/openapi.json',
)


# sync to proxy
sync.sync()


@app.get('/api')
async def index():
    return {'message': 'Hello, detox-proxy!'}


@app.get(
    '/api/blockaddress',
    description='Record block address',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_200_OK: {
            'model': List[schema.Block],
            'description': 'Successful response',
        },
        status.HTTP_401_UNAUTHORIZED: {
            'description': 'Unauthorized',
        },
    },
)
async def get_block_address_list():
    results = []
    with db.session_scope() as s:
        blocks = s.query(db.Block).all()
        for b in blocks:
            results.append(schema.Block.from_db(b))

    return results


@app.post(
    '/api/blockaddress',
    description='Record block address',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_200_OK: {
            'model': schema.Block,
            'description': 'Successful response',
        },
        status.HTTP_401_UNAUTHORIZED: {
            'description': 'Unauthorized',
        },
    },
)
async def set_block_address(block_create_list: List[schema.BlockCreate]):
    results = []
    with db.session_scope() as s:
        results = [b.create(s) for b in block_create_list]
        s.commit()
        schema.sync_block()

    return results


@app.put(
    '/api/blockaddress',
    description='Update block address',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_200_OK: {
            'model': List[schema.Block]
        },
        status.HTTP_401_UNAUTHORIZED: {
            'description': 'token is required'
        },
        status.HTTP_404_NOT_FOUND: {
            'description': 'display not found'
        },
    },
)
async def update_block_address(update_list: List[schema.Block]):
    result = [x.update() for x in update_list]
    schema.sync_block()
    return result


@app.delete(
    '/api/blockaddress',
    description='Delete block address',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_200_OK: {
            'description': 'Successful response'
        },
        status.HTTP_403_FORBIDDEN: {
            'description': 'Forbidden'
        },
        status.HTTP_404_NOT_FOUND: {
            'description': 'Block Address not found',
        },
    },
)
async def delete_block_address(delete_list: List[int]):
    with db.session_scope() as s:
        for del_id in delete_list:
            d = s.query(db.Block).get(del_id)
            if d is None:
                raise HTTPException(status.HTTP_404_NOT_FOUND)
            s.delete(d)
        s.commit()
        schema.sync_block()

    return ""


# PAC FILE

HOST = os.environ['DETOX_PROXY_PROXY_HOST']
HTTP = os.environ['DETOX_PROXY_PROXY_HTTP_PORT']

pac = f"""function FindProxyForURL(url, host) {{
    return "HTTP {HOST}:{HTTP}";
}}
"""


@app.get(
    '/proxy.pac',
    description="Proxy Auto Configuration file"
)
async def get_pac():
    headers = {'Content-Type': 'application/x-ns-proxy-autoconfig'}
    return Response(pac, headers=headers)
