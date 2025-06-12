# README

### Instalation requirements

- `nodejs` 16.13.0

### Installation

```bash
npm i
```

### Configuration

**IMPORTANT!!! Contact with developer to get variables listed in this section!!!**

Variables needed to run JIRA integration test:

| Name               | Additional info                                                                              |
| ------------------ | -------------------------------------------------------------------------------------------- |
| JIRA_TEST_USER     | User name login into JIRA by UI                                                              |
| JIRA_TEST_USER_PWD | User password login into JIRA by UI                                                          |
| MP_JIRA_URL        | ---                                                                                          |
| MP_JIRA_PROJECT    | Project integrated with application instance where tests will be run (`EOSCO<project type>`) |

Env variables can be set as described in [enviroment variables](https://docs.cypress.io/guides/guides/environment-variables#Option-1-configuration-file).

Variables needed to run PROVIDER PORTAL integration test:

| Name | Additional info |
| ---- | --------------- |

| PROVIDER_PORTAL_URL  
| MARKETPLACE_URL  
| PROVIDER_PORTAL_REFRESH_TOKEN  
| PROVIDER_PORTAL_CLIENT_ID

Env variables can be set as described in [enviroment variables](https://docs.cypress.io/guides/guides/environment-variables#Option-1-configuration-file).

Examples:

- Create `cypress.env.json`

```json
{
  "JIRA_TEST_USER": "...",
  "JIRA_TEST_USER_PWD": "...",
  "MP_JIRA_URL": "http://...",
  "MP_JIRA_PROJECT": "EOSCO<project_type>",
  "PROVIDER_PORTAL_URL": "https://sandbox.providers.eosc-portal.eu",
  "MARKETPLACE_URL": "https://beta.marketplace.eosc-portal.eu/",
  "PROVIDER_PORTAL_CLIENT_ID": "...",
  "PROVIDER_PORTAL_REFRESH_TOKEN": "...",
  "AAI_TOKEN_URL": "..."
}
```

- Write in terminal variables with prefix `CYPRESS_` or `cypress_`

```bash
export CYPRESS_JIRA_TEST_USER="...";
export CYPRESS_JIRA_TEST_USER_PWD="...";
export CYPRESS_MP_JIRA_URL="...";
export CYPRESS_MP_JIRA_PROJECT="...";
export PROVIDER_PORTAL_URL="...";
export MARKETPLACE_URL="...";
export PROVIDER_PORTAL_CLIENT_ID="...";
export PROVIDER_PORTAL_REFRESH_TOKEN="...";
export AAI_TOKEN_URL="..."
```

### How to run the test suite?

- Run http server before running the tests

```bash
e.g docker run -p 80:80 kennethreitz/httpbin
```

- Run in preview mode

```bash
yarn run cypress open
```

- Run in headless mode

```bash
yarn run cy:run
```

- Run only integration with JIRA test

```bash
npm run cy:run-jira-integration
```

- Run only integration with PROVIDER PORTAL test

```bash
npm run cy:run-provider-portal-integration
```

- Run to seed the database

```bash
./bin/rails dev:prime_e2e
```

### Testing different instances

To run e2e tests on URL other than `localhost` preset variable `base url` by:

- Add variable to OS with command `export CYPRESS_BASE_URL=<domain>`
- Change a value of `baseUrl` in `cypress.json` (not recommended)

### Available instances

- Production: https://marketplace.eosc-portal.eu
- Staging (beta) https://marketplace-beta.docker-fid.grid.cyf-kr.edu.pl/
- Master (deploy from master branch) http://marketplace.docker-fid.grid.cyf-kr.edu.pl/
- Pull request (nrPR = Pull request number in github): http://pr-nrPR.docker-fid.grid.cyf-kr.edu.pl/

### Running on

- Pull Requests Github Actions with title `Integration tests`
