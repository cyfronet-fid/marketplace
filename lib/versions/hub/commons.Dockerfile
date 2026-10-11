# Image of the EOSC commons bundle (header, footer, to-top button) of a
# discovery hub and of its marketplace instance: the staging build of
# eosc-pl-common (pl) or eosc-portal-common (marketplace), served by nginx.
# The hub nginx (nginx.conf next to this file) publishes the image as
# /commons/ of the hub; the api gives that URL to the UI as EOSC_COMMONS_URL
# with EOSC_COMMONS_ENV=staging, and the marketplace instance of the variant
# loads the same bundle through EOSC_COMMONS_BASE_URL.
# Build context: the checkout of the commons repository with the staging
# environment of lib/versions/hub/commons/<variant> copied in by
# deploy-hubs.sh: env/env.staging.js and the configuration JSON files with
# the links of the staging hosts. The environment name is the suffix of the
# bundle files (index.staging.min.js, index.staging.min.css).
ARG NODE_VERSION=20

FROM node:${NODE_VERSION}-bookworm AS build
WORKDIR /commons
# The same install as the Dockerfile of the repository.
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN test -f env/env.staging.js \
    || { echo "env/env.staging.js is missing: deploy-hubs.sh copies the staging environment into the checkout"; exit 1; } \
    && npx gulp build --production --env env/env.staging.js

FROM nginx:1.27-alpine
COPY --from=build /commons/dist /usr/share/nginx/html
EXPOSE 80
