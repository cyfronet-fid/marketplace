# Stage 0: Get ruby version
ARG RUBY_VERSION=3.3.6

# Stage 1: Building dependencies
FROM ruby:${RUBY_VERSION}-alpine AS builder

# Setting environment variables
ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Installing necessary packages for compilation
RUN apk add --no-cache \
    build-base \
    tzdata \
    postgresql-dev \
    postgresql-client \
    zlib-dev \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    npm \
    yajl \
    librsvg \
    vips \
    imagemagick \
    shared-mime-info

# Installing yarn via npm
RUN npm install -g yarn

# Installing gems needed for building
RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | tr -d ' ')" --no-document
RUN gem install foreman --no-document

# Creating application directory
WORKDIR /marketplace

# Copying dependency files
COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

# Installing dependencies - using system path instead of deployment mode
RUN bundle config set --local without 'development test' && \
    bundle install --jobs=4 && \
    yarn install --production --frozen-lockfile

# Copying application code
COPY . /marketplace

# Compiling assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rake assets:precompile

# Stage 2: Final image
FROM ruby:${RUBY_VERSION}-alpine

# Setting environment variables
ENV RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_SERVE_STATIC_FILES=true

# Installing only required production packages
RUN apk add --no-cache \
    tzdata \
    postgresql-client \
    vips-tools \
    imagemagick \
    shared-mime-info \
    nodejs \
    librsvg \
    rsvg-convert \
    yajl \
    bash

# Creating non-root user
RUN addgroup -S app && \
    adduser -S -G app app

# Creating directory structure
RUN mkdir -p /marketplace/tmp/pids /marketplace/log /marketplace/public && \
    chown -R app:app /marketplace

# Setting working directory
WORKDIR /marketplace

# Copying gems from builder stage - ensuring all paths are properly copied
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /marketplace /marketplace

# Ensure permissions are correct
RUN chown -R app:app /marketplace

# Switching to non-root user
USER app

# Exposing port
EXPOSE 3000

# Running the server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]