FROM elixir:alpine

RUN apk add streamlink --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk add yt-dlp ffmpeg git
COPY . /app
WORKDIR /app
RUN mix local.hex --force
RUN mix deps.get
RUN MIX_ENV=prod mix release
CMD ["/app/_build/prod/rel/avina/bin/avina", "start"]
