# README

Market place is...

## Development environment

### Requirements

We will need:
  * ruby (specific version can be found in [.tool-versions](.tool-versions)).
    Recommented way to manage ruby versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-ruby](https://github.com/asdf-vm/asdf-ruby) plugin
  * nodejs (specific version can be found in [.tool-versions](.tool-versions)).
    Recommented way to manage nodejs versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) plugin.
  * [postgresql](https://www.postgresql.org)

### Setup

  * First time run `/bin/setup`. It will install bundler, foreman,
    dependencies and setup databases (development and test).
  * After update run `/bin/update`. It will update dependencies, run db
    migrations and restart currently started application.

### Generating DB entries for development
To simplify development `dev:prive` rake task is created. Right now it generates
services with random title and description (this generation is done using
`faker` gem). In the future this task will be extended with additional data.

```
rails dev:prime     # Remove existing services and generate 100 new services
rails dev:prime[50] # Remove existing services and generate 50 new services
```

## Run

To start web application in development mode (with auto refresh capability when
css/js files change) use following command:

```
./bin/server
```
