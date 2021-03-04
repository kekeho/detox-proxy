FROM nimlang/nim:1.4.2-alpine


RUN mkdir /code
COPY ./detox_proxy.nimble /code
COPY ./nim.cfg /code

WORKDIR /code
RUN nimble install -d -y

COPY ./ /code
RUN nimble build -y

EXPOSE 5001
CMD [ "./detox_proxy" ]
