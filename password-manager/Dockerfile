FROM node:14.13.1-slim as build

WORKDIR /app

COPY package.json /app

RUN yarn install && yarn cache clean

COPY . /app

CMD ["yarn", "run", "build"]

