# syntax=docker/dockerfile:1

# HINWEIS: Docker nur verwenden, wenn es nicht anders geht, da die System-Werte sonst nicht korrekt ermittelt werden können.
#          Docker widerspricht an der Stelle dem Sinn der App, da die Werte des Host-Systems ermittelt werden sollen
# So startet man die App:
# docker build -t sinatra-server-api .
# docker run --rm -p 4567:4567 \
#  -- name sinatra-server-api \
#  -v /var/run/docker.sock:/var/run/docker.sock \
#  -e API_TOKEN=deinToken \
#  sinatra-server-api

FROM ruby:3.3-slim

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    APP_ENV=development \
    PORT=4567

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs 4 --retry 3

COPY . .

EXPOSE 4567

CMD ["bash", "-lc", "bundle exec rackup -p ${PORT:-4567} -o 0.0.0.0"]
