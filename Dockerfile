FROM python:3.13.2-alpine3.21

ENV PYTHONUNBUFFERED=1

WORKDIR /code

COPY requirements.txt /code/

RUN python -m pip install --upgrade pip && \
    pip install -r requirements.txt

COPY . /code/
