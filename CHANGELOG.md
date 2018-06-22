# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

Please view this file on the master branch, on stable branches it's out of date.

## [Unreleased]

### Added
- Basic application structure and configuration (@mkasztelnik)
- Service model, simple index and show pages integrated with elasticsearch (@mkasztelnik)
- Initialization of elastic search indexes on application setup (@mszostak)
- Sentry integration (@mkasztelnik)
- Profile page with basic info and unauthenticated user redirection (@martaswiatkowska @jswk)
- Pundit for user authorization (@mkasztelnik)
- ENV variables to configure checkin URLs and root application URL (@mkasztelnik)
- Custom git hooks for checking code syntax via RuboCop and commit message formatting (@mszostak)
- Custom git commit message template (@mszostak)
- Redirect user into `/` after checkin login failure (@mkasztelnik)
- Service categories (@mkasztelnik)
- Service order possibility (@mkasztelnik)
- Configure `database_cleaner` for rspec (@mkasztelnik)
- Service terms of use with markdown renderer (@mkasztelnik)
- Send email to order owner when order is created or updated (@mkasztelnik)
- User can ask about processed order (@mkasztelnik)

### Changed

### Deprecated

### Removed
- Remove default devise session routes, only logout remain (@mkasztelnik)

### Fixed

### Security
