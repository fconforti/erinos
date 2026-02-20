FROM ruby:3.4-alpine

RUN apk add --no-cache build-base sqlite-dev yaml-dev tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 4.0.6 && bundle install

COPY . .

CMD ["ruby", "api.rb"]
