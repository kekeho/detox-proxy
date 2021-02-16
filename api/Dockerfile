FROM python:3.9-slim-buster

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
COPY ./Pipfile.lock /code
RUN python -m pipenv install

COPY ./ ./

CMD [ "python", "-m", "pipenv", "run", "start" ]
