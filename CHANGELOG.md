# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

Please view this file on the master branch, on stable branches it's out of date.

## [Unreleased]

### Added
- Basic application structure and configuration (@mkasztelnik)
- Service model, simple index and show pages integrated with elasticsearch (@mkasztelnik)
- Initialization of elastic search indexes on application setup (@michal-szostak)
- Sentry integration (@mkasztelnik)
- Profile page with basic info and unauthenticated user redirection (@martaswiatkowska @jswk)
- Pundit for user authorization (@mkasztelnik)
- ENV variables to configure checkin URLs and root application URL (@mkasztelnik)
- Custom git hooks for checking code syntax via RuboCop and commit message formatting (@michal-szostak)
- Custom git commit message template (@michal-szostak)
- Redirect user into `/` after checkin login failure (@mkasztelnik)
- Service categories (@mkasztelnik)
- Service order possibility (@mkasztelnik)
- Configure `database_cleaner` for rspec (@mkasztelnik)
- Service terms of use with markdown renderer (@mkasztelnik)
- Send email to order owner when order is created or updated (@mkasztelnik)
- User can ask about processed order (@mkasztelnik)
- Create first draft Ui layout (@kosmidma)
- Playground for designing views (@mkasztelnik)
- Bootstrap 4 style for will_paginate (@mkasztelnik)
- Possibility to configure development DB using ENV variables (@mkasztelnik)
- Possibility to configure elasticsearch URL using ENV variable (@wziajka)
- Bootstrap JS and font awesome regular (@michal-szostak)
- Service tagline (@martaswiatkowska)
- Transfer tabs from playground to services(@kosmidma)
- Add styling for services, improve global styles (@kosmidma)
- User affiliations (@mkasztelnik)
- Service and categories database seed (@bwilk)
- Conditional software version placeholder in frontend (@bwilk)
- Service owner can manage owned services (@mkasztelnik)
- Add rating for Service (@kmarszalek)
- Add JIRA integration (marketplace to jira) (@michal-szostak)
- Add open access services (#martaswiatkowska)
- Add HAML validation to overcommit via `haml-lint` (@michal-szostak)
- Add SCSS validation to overcommit via `scss-lint` (@michal-szostak)
- Jira webhook integration (@michal-szostak)
- Add footer at the bottom of the page (@kosmidma)
- Add styling for user's profile (@kosmidma)
- Add and styling static elements to sidebar (@kosmidma)
- Update service view (@kosmidma)
- Styling My Services view (@kosmidma)
- Styling Order Placement view (@kosmidma)
- Add dotenv gem (@michal-szostak)
- Change checkin service (@wziajka)
- Add filling database with services, categories and relations between them in seeds.rb (@goreck888)
- Styling Order Details view (@kosmidma)
- Create ticket in JIRA by open service order with adequate status "Done" (@goreck888)
- Added providers link (@martaswiatkowska)
- Styling Home view (@kosmidma)
- Corrections My Profile view (@kosmidma)
- Service opinion form and active job that send email to user about rating service 5 days after order is ready (@kmarszalek)
- Sort services via selection of options in select box (@michal-szostak)
- Store Jira internal id in order change (@mkasztelnik)
- Create new order change when Jira comment is posted (@mkasztelnik)
- Show number of services in category (@mkasztelnik)
- Possibility to define checkin identifier and secret using env variables (@mkasztelnik)
- Add breadcrumbs to order index and show (@mkasztelnik)


### Changed
- Upgrade Sprockets gem to avoid CVE-2018-3760 vulnerability (@mkasztelnik)
- Fix and refactor seeds.rb to work properly (@goreck888)
- Update services and category list in data.yml (@goreck888)
- Update home view with static version (@kmarszalek)
- Upgrade service detail view (@kmarszalek)

### Deprecated

### Removed
- Remove default devise session routes, only logout remain (@mkasztelnik)

### Fixed

### Security
