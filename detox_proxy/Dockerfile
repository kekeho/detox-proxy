FROM nimlang/nim:1.4.2-alpine


RUN mkdir /code
COPY ./detox_proxy.nimble /code
COPY ./nim.cfg /code

WORKDIR /code
RUN nimble install -d -y
# fix bcrypt
RUN cat /root/.nimble/pkgs/easy_bcrypt-2.0.3/easy_bcrypt.nim | sed "s/.. <BCRYPT_HASHSIZE/.. (BCRYPT_HASHSIZE - 1)/" > /root/.nimble/pkgs/easy_bcrypt-2.0.3/easy_bcrypt.nim


COPY ./ /code
RUN nimble build -y

EXPOSE 5001
CMD [ "./detox_proxy" ]
