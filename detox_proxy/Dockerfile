FROM nimlang/nim:1.4.2-alpine


RUN mkdir /code
COPY ./ /code

WORKDIR /code
RUN nimble build

EXPOSE 5001
CMD [ "./detox_proxy" ]

