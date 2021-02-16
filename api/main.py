# Copyright (c) 2021 Hiroki Takemura (kekeho)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from fastapi import FastAPI
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
    return u.create()
