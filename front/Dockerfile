FROM caddy:2.2.1-alpine


# Install elm

RUN apk update
RUN apk add gzip

RUN mkdir /elm
WORKDIR /elm
RUN wget https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
RUN gunzip binary-for-linux-64-bit.gz

RUN mv binary-for-linux-64-bit elm
RUN chmod +x elm
RUN cp elm /usr/local/bin/elm


# build front

RUN mkdir /code
RUN mkdir /public
COPY ./src /code/src
COPY ./elm.json /code

WORKDIR /code
RUN elm make src/Main.elm --output=/public/static/js/elm.js --optimize


# Copy public

COPY ./public /public
COPY Caddyfile /code/

CMD ["caddy", "run", "--config", "/code/Caddyfile", "--adapter", "caddyfile"]
