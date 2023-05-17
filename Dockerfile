FROM alpine:latest

RUN apk add yt-dlp ffmpeg git elixir make gcc musl-dev curl-dev python3 py3-pip
#RUN apk add streamlink --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN pip install -U streamlink
COPY . /app
WORKDIR /app
RUN mix local.hex --force
RUN mix deps.get
RUN mix local.rebar --force
RUN MIX_ENV=prod mix release
CMD ["/app/_build/prod/rel/avina/bin/avina", "start"]
