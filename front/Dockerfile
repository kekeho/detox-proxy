FROM caddy:2.2.1-alpine


# build elm from source

RUN apk update
RUN apk add --no-cache ghc cabal wget musl-dev zlib-dev zlib-static ncurses-dev ncurses-static git

RUN mkdir /elm
WORKDIR /elm

RUN git clone https://github.com/elm/compiler.git
WORKDIR /elm/compiler

RUN rm -r docs hints installers worker

RUN cabal new-update
RUN cabal new-build --ghc-option=-optl=-static --ghc-option=-split-sections
RUN cp ./dist-newstyle/build/*-linux/ghc-*/elm-*/x/elm/build/elm/elm /usr/local/bin/elm


# remove debug symbol
RUN strip -s /usr/local/bin/elm

RUN rm -rf /elm


# build front

RUN mkdir /code
RUN mkdir /public
RUN mkdir /cert
COPY ./src /code/src
COPY ./elm.json /code

WORKDIR /code
RUN elm make src/Main.elm --output=/public/static/js/elm.js --optimize


# Copy public

COPY ./public /public
COPY Caddyfile /code/

CMD ["caddy", "run", "--config", "/code/Caddyfile", "--adapter", "caddyfile"]
