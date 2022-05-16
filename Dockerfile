FROM elixir:alpine

RUN apk add yt-dlp ffmpeg
RUN apk add streamlink --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
