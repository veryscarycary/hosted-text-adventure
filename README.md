# Hosted Text Adventure

<img width="1234" alt="image" src="https://github.com/veryscarycary/hosted-text-adventure/assets/16945851/f0b2e8d5-86f3-4d1a-9ba8-3672c2b4a0b0">

## Dependencies

- Docker (install at https://docs.docker.com/get-docker/)

## Install

Docker instructions to run:

BOTH TOGETHER:

```
docker compose up
```

Websocket container

```
docker build -t my-ruby-app .
docker run -it -p 3000:3000 my-ruby-app
```

Ruby process container

```
docker run -p 3001:3001 --network my-network -t text-adventure
```
