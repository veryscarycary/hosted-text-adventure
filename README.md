# Hosted Text Adventure

____________________________________

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