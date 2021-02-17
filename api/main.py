# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from typing import Optional
from fastapi import FastAPI, HTTPException, Response
from fastapi import status

import schema
import db

# Init db
db.Base.metadata.create_all(bind=db.engine)

app = FastAPI(
    docs_url='/docs',
    openapi_url='/openapi.json',
)


@app.get('/')
async def index():
    return {'message': 'Hello, detox-proxy!'}


@app.post(
    '/user',
    description='Create user',
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_201_CREATED: {
            'model': schema.User,
            'description': 'Successful Response (created)',
        },
        status.HTTP_409_CONFLICT: {
            'description': 'Email already registered',
        }
    },
)
async def create_user(u: schema.CreateUser):
    new_user = await u.create()
    return new_user


@app.post(
    '/user/login',
    description='login',
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_200_OK: {
            'description': 'Set token as cookie'
        },
    },
)
async def login(login: schema.LoginUser):
    token: Optional[str] = login.login()
    if token is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED)

    maxage = ''
    if login.remember:
        maxage = 'Max-Age=7776000;'

    cookie = f'token={token}; HttpOnly; '
    cookie += f'SameSite=Strict; Secure; {maxage} path=/;'
    headers = {'Set-Cookie': cookie}
    return Response(None, status.HTTP_202_ACCEPTED, headers=headers)
