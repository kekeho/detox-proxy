# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


from fastapi_mail import FastMail, ConnectionConfig
import os


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
