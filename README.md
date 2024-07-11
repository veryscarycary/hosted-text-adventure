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

(if hosting provider doesn't spin up 2 separate services with `docker compose up` above, use this for the websocket server service)

```
docker build -t websocket-server .
docker run -it -p 3000:3000 websocket-server
```

Ruby process container

(if hosting provider doesn't spin up 2 separate services with `docker compose up` above, use the `farm-text-adventure` repo's tcp server Dockerfile (Dockerfile-tcp-server) and create the tcp server service based on that repo. Then run `docker build -f ./Dockerfile-tcp-server -t text-adventure .`)

If image is already built and tagged as `text-adventure` (from docker compose up or from the target repo), you can run it with this command:

```
docker run -p 3001:3001 --network my-network -t text-adventure
```
