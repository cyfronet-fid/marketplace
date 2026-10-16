# Image of a discovery hub UI (pl-discovery-hub, eosc-search-service): the
# Angular build served by nginx, with /api/ proxied to the api service (see
# nginx.conf next to this file, mounted by docker-compose-hub-<variant>.yml).
# Build context: the ui/ directory of the hub checkout.
#
# NG_* variables are read at build time by ng-node-environment (prebuild
# script) and compiled into the application; the collections prefix must be
# the same as COLLECTIONS_PREFIX of the api.
ARG NODE_VERSION=19.2.0

FROM node:${NODE_VERSION}-alpine AS build
ARG NG_COLLECTIONS_PREFIX=""
ENV NG_COLLECTIONS_PREFIX=${NG_COLLECTIONS_PREFIX} \
    NODE_OPTIONS=--max-old-space-size=4096 \
    NX_DAEMON=false
WORKDIR /ui
# postinstall runs decorate-angular-cli.js; the same install as the CI.
COPY package.json package-lock.json decorate-angular-cli.js ./
RUN npm i --force
COPY . .
# The same steps as `npm run build` (prebuild generates the environment file
# with ng-node-environment, then nx build) without the `eslint --fix` of the
# generated file, which fails in eosc-search-service with a rule-loading error
# of its eslint setup and only formats that file.
RUN node node_modules/ng-node-environment/index.js --out='./apps/ui/src/environments/environment.generated.ts' \
    && npx nx build

FROM nginx:1.27-alpine
COPY --from=build /ui/dist/apps/ui /usr/share/nginx/html
EXPOSE 80
