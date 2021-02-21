# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from typing import Optional, List
from fastapi import FastAPI, HTTPException, Response
from fastapi import status
from fastapi.params import Cookie

import schema
import db

# Init db
db.Base.metadata.create_all(bind=db.engine)

app = FastAPI(
    docs_url='/api/docs',
    openapi_url='/api/openapi.json',
)


@app.get('/api')
async def index():
    return {'message': 'Hello, detox-proxy!'}


@app.post(
    '/api/user',
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


@app.get(
    '/api/user/activate/{token:str}',
    description='Activate user',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_307_TEMPORARY_REDIRECT: {
            'description': 'Successful Response (user account activated)',
        },
        status.HTTP_400_BAD_REQUEST: {
            'description': 'Verify token is missing'
        },
        status.HTTP_403_FORBIDDEN: {
            'description': 'Invalid token'
        },
    },
)
async def activate_user(token: str):
    with db.session_scope() as s:
        v: Optional[db.CreateUserVerify] = db.CreateUserVerify.get(s, token)
        if v is None:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                "Invalid token")

        # don't care is_active
        u: Optional[db.User] = s.query(db.User).get(v.user)
        if u is None:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR)
        u.is_active = True
        s.delete(v)

        token = db.Token.issue_token(u)
        maxage = 'Max-Age=7776000;'
        cookie = f'token={token}; HttpOnly; '
        cookie += f'SameSite=Strict; Secure; {maxage} path=/;'
        header = {
            'Set-Cookie': cookie,
            'Location': '/'
        }

    return Response(None, status.HTTP_307_TEMPORARY_REDIRECT, headers=header)


@app.post(
    '/api/user/login',
    description='login',
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_200_OK: {
            'description': 'Set token as cookie'
        },
        status.HTTP_401_UNAUTHORIZED: {
            'description': 'username/password wrong'
        }
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


@app.get(
    '/api/user',
    description='Get login user info',
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_200_OK: {
            'model': schema.User,
            'description': 'Successful Response',
        },
        status.HTTP_401_UNAUTHORIZED: {
            'description': 'Login failed',
        },
    },
)
async def get_loginuser_info(token: Optional[str] = Cookie(None)):
    if token is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED)

    with db.session_scope() as s:
        u = db.Token.get_user(s, token)
        if u is None:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED)

        return schema.User.from_db(u)


@app.post(
    '/api/user/blockaddress',
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
async def set_block_address(block_create_list: List[schema.BlockCreate],
                            token: Optional[str] = Cookie(None)):
    if token is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED)

    results = []
    with db.session_scope() as s:
        u = db.Token.get_user(s, token)
        if u is None:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED)

        results = [b.create(s, u) for b in block_create_list]
        s.commit()

    return results
