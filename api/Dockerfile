FROM python:3.9-slim-buster

# Install GCC
RUN apt update
RUN apt install -y build-essential


# Create dir
RUN mkdir /code
RUN mkdir /projectimage
WORKDIR /code

# Change user
RUN useradd containeruser
RUN chown -R containeruser ./
RUN chown -R containeruser /projectimage
RUN mkdir /home/containeruser
RUN chown -R containeruser /home/containeruser
USER containeruser

# Install deps
RUN pip install pipenv
COPY ./Pipfile /code
RUN python -m pipenv install

COPY ./ ./

CMD [ "python", "-m", "pipenv", "run", "start" ]
