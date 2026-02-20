FROM ruby:3.4-alpine

RUN apk add --no-cache build-base

WORKDIR /app/channels/telegram

COPY gems/erinos-client /app/gems/erinos-client
COPY channels/telegram/Gemfile channels/telegram/Gemfile.lock ./
RUN bundle install

COPY channels/telegram/ .

CMD ["bundle", "exec", "ruby", "bot.rb"]
