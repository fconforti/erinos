FROM ruby:3.4-alpine

RUN apk add --no-cache build-base

WORKDIR /app/channels/cli

COPY gems/erinos-client /app/gems/erinos-client
COPY channels/cli/Gemfile channels/cli/Gemfile.lock ./
RUN bundle install

COPY channels/cli/ .

ENTRYPOINT ["bundle", "exec", "ruby", "cli.rb"]
