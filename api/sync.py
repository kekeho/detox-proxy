import os
from typing import Dict
import requests
import datetime
import multiprocessing as mp

import db


PROXY_API_PORT = os.environ['DETOX_PROXY_PROXY_API_PORT']


def send_user(u: Dict[str, str]):
    print(datetime.datetime.now())
    r = requests.post(f'http://proxy:{PROXY_API_PORT}/user/regist',
                      json={'username': u['username'],
                            'hashed_password': u['hashed_password']})
    if r.status_code != 201:
        raise Exception()


def sync_user():
    user_list = []

    with db.session_scope() as s:
        users = s.query(db.User).all()
        for u in users:
            u_ = {'username': u.username,
                  'hashed_password': u.hashed_password}
            user_list.append(u_)

    with mp.Pool(10) as p:
        p.map(send_user, user_list)


def sync():
    sync_user()
