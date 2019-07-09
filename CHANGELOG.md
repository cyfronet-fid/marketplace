# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

Please view this file on the master branch, on stable branches it's out of date.

## [Unreleased]

### Added
- Country of customer and country of collaboration fields (@goreck888)
- Country fields transfer to jira issues (@goreck888)
- Create project copy (@mkasztelnik)

### Changed

- Redirection to a service upon choice made by autocomplete in search bar (@bwilk)
- Reimplemented filters and categories after creating indexes in Elasticsearch (@bwilk)
- Expand all projects on projects index view (@mkasztelnik)
- Improvements for project box views (@mkasztelnik)
- Project card redesigned (@mkasztelnik)
- Move ResearchArea association from project item to the project
- Content of mail templates by voucher accept (@goreck888)

### Deprecated

### Removed
- Project filter removed from projects index view (@mkasztelnik)
- Affiliations were removed from all views (@mkasztelnik)

### Fixed

- Blocked access to the draft service via direct link
- Category and filter counters (@bwilk)
- Hierarchical filters deactivation buttons (@bwilk)
- Choice of "best match" sorting strategy after search (@bwilk)
- Maintaining sort order when filters are applied (@bwilk)
- Redirection to project edit view on project creation failure while ordering (@bwilk)

### Security

## [1.11.1] 2019-06-05

### Fixed
- fixed button dismiss action

## [1.11.0] 2019-06-04

### Added
- Cookie policies consent popup (@mkasztelnik)
- Project details view (@martaswiatkowska)
- Master / sub issue jira integration
- jira master / sub issue migration rake task

### Changed
- Improve empty project description (@mkasztelnik)
- Improve collapse / expand all behaviour for filters (@michal-szostak)
- Move additional_information from project_item to project (@martaswiatkowska)

### Removed
- Remove rating filter from the view until we have enough ratings to show it (@mkasztelnik)
- Remove default project creation (@mkasztelnik)
- Remove duplicated project fields from project-item (@martaswiatkowska)

### Fixed
- Don't add `+` instead of space to query value during filtering (@mkasztelnik)
- Showing draft services on search in backoffice (@martaswiatkowska)
- Validation logo format (@martaswiatkowska)

## [1.10.0] 2019-05-13

### Added
- Added tagline to elasticsearch index (@martaswiatkowska)

### Changed
- Research area filter changed to hierarchical and multi-select (@mkasztelnik)
- Rename `ServiceCategory` model to `Categorization` (@mkasztelnik)
- Autocomplete routing (@martaswiatkowska)
- Fields weights in elasticearch (@martaswiatkowska)

### Fixed
- Unescape query string while showing it to the user (@mkasztelnik)
- Multiplication of parameter q in autocomplete url(@martaswiatkowska)

## [1.9.0] - 2019-05-06

### Added
- Tracking code for Hotjar (@abacz)

## [1.8.1]- 2019-04-26

### Fixed
- Don't close already opened filter in test (@mkasztelnik)
- Don't duplicate results when service belongs to e.g. 2 selected in filter
  providers (@mkasztelnik)

## [1.8.0] - 2019-04-18

### Added
- search autocomplete (@martaswiatkowska)
- Highlights on main search (@martaswiatkowska)
- "collapse all" for service filters (@goreck888)
- "looking for" header in search (@goreck888)
- Controller for active filters (@goreck888)
- Counter in services view (@goreck888)

### Changed
- ruby and js dependencies upgraded (@mkasztelnik)
- Project item attributes refactored (@mkasztelnik)
- Fix reset services page after change number of items and after category change(@goreck888)
- `SO-1` jira field changed from url to json (@mkasztelnik)
- `rubocop-rails` gem was renamed to `rubocop-rails_config` (@mkasztelnik)
- Site width 1180px
- Shadow box for service header
- Yellow bullets and arrows in sidebar lists
- All services link moved above the category list
- Autocomplete content are serve only from ajax request (@martaswiatkowska)
- View of services navigation bar (@goreck888)

### Fixed
- Link to all services should contain filter params (@mkasztelnik)
- Use searchkick reindex in setup instead of elasticsearch import (@martaswiatkowska)
- Show 404 error page when affiliation is not found (@mkasztelnik)
- Use custom error pages with webpage layout in production environment (@mkasztelnik)
- Fix bug with JIRA issue creation (attribute mapping to SO-1) (@michal-szostak)
- Remove std out/err logs from test suite output (@mkasztelnik)
- Fix show opinions for open access services (@mkasztelnik)
- Fix authorising affiliation from user affiliations, not affiliations at all (@goreck888)


## [1.7.0] - 2019-04-01

### Added
- Link to the tutorial of creating attributes in backoffice (@goreck888)
- External ID input to backoffice provider's form (@michal-szostak)
- External import task (@michal-szostak)
- Initial implementation of usage Searchkik (@martaswiatkowska)

### Changed
- Filters refactored and moved into `Service::Filterable` concern (@mkasztelnik)
- Filters cleared when user type new query (@mkasztelnik)
- Filters not cleared when changing category (@mkasztelnik)
- Button styling in backoffice provider form (@michal-szostak)

### Removed
- Remove terms and conditions from service order confirmation view (@mkasztelnik)

### Fixed
- Show accept terms of use only when terms are given for the service (@mkasztelnik)

## [1.6.0] - 2019-03-18

### Added
- OfferType field in jira (@martaswiatkowska)

### Changed
- Improvements in backoffice service form (@martaswiatkowska)

### Removed
- Remove unused `orders` and `order_changes` tables from `db/schema.rb` (@mkasztelnik)

### Fixed
- service creation bug (@martaswiatkowska)
- integer and range validation bug (@michal-szostak / @martaswiatkowska)

## [1.5.1] - 2019-03-15


### Fixed
- Fix infinitive loop while updating main service category (@mkasztelnik)

### Security
- Rails upgraded with fixes for: CVE-2019-5418, CVE-2019-5419 and CVE-2019-5420 (@mkasztelnik)

## [1.5.0] - 2019-03-06

### Added
- Offer status (@martaswiatkowska)
- markdown rendering in offer's description (@goreck888)
- Offers parameters in backoffice - initial (@martaswiatkowska)
- Order Target field to Service (@michal-szostak)
- Passing of Order Target field to JIRA (field `SO-ServiceOrderTarget`) (@michal-szostak)

### Fixed
- Date and time display in order history

## [1.4.1] - 2019-02-28

### Fixed
- Small view error in my order detail page

## [1.4.0] - 2019-02-26

### Added
- voucher_id in aod_voucher_accepted email (@kmarszalek)
- voucher_id updates from jira (@michal-szostak)
- `elasticsearch` version added to `.tool-versions` file (@mkasztelnik)
- Offer type (`normal`, `open_access`, `catalog`) with service type taken as
  default (@mkasztelnik)
- Offer can be selected from `service#show` (@mkasztelnik)
- Date attribute `min` and `max` validation (@mkasztelnik)
- voucher_id display in project items's details (@michal-szostak)
- Add `Attribute::QuantityPrice` (@mkasztelnik)

### Changed
- Change service phase values into keys (@mkasztelnik)
- Change names of buttons and headers (@goreck888)
- Changes in aod_voucher_accepted mails and new mail sended after rejection (@martaswiatkowska)
- Change styles for project item details (@jarekzet)

## [1.3.0] - 2019-02-11

### Added
- Searchable backoffice services index view (@mkasztelnik)
- Hint to url inputs in service edit view (@kmarszalek)

### Changed
- Offers displaying on backoffice and portal view (@martaswiatkowska)
- Height of the textarea in the ofers form (@martaswiatkowska)
- Phase to select on service edit view (@kmarszalek)
- Phase to enum in Service model (@kmarszalek)

## [1.2.1] - 2019-01-30

### Added
- "about Marketplace" static page (@goreck888)

### Changed
- External Sources EID type has been changed to string (@michal-szostak)

### Fixed
- ProjectItem details view crash for open access services (@michal-szostak)
- Order mailing (@michal-szostak)

## [1.2.0] - 2019-01-29

### Added
- User needs to select "Research area" while ordering service (@mkasztelnik)
- Add voucher support in service ordering (@michal-szostak)
- Basic CRUD for backoffice Research areas (@mkasztelnik)
- Basic CRUD for backoffice Categories (@mkasztelnik)
- New custom fields for voucher in jira (@martaswiatkowska)
- Basic CRUD for backoffice Providers (@mkasztelnik)
- Basic CRUD for backoffice Platforms (@mkasztelnik)
- Voucher styling (@jarekzet)
- Vouchers emails (@martaswiatkowska)
- External Sources information for services (@michal-szostak)

### Fixed
- RWD for offer selection (@jarekzet)
- Show `*` near order research area field, show errors when research area is not
  selected (@mkasztelnik)
- Remove shell command invocation in one of the test (@mkasztelnik)

## [1.1.0] - 2019-01-18

### Added
- Breadcrumbs for Admin and Back office sections (@mkasztelnik)
- Add `service_portfolio_manager` role (@mkasztelnik)
- Possibility of adding offers to the services (@martaswiatkowska)
- `SO-ProjectName` to issue created in JIRA (@michal-szostak)
- Active filter list & remove in filter sidebar (@michal-szostak)
- Status to service (@martaswiatkowska)
- Add JIRA mapping for `CP-UserGroupName` and `CP-ProjectInformation` (@michal-szostak)

### Changed
- Unify Back office and Admin layout navbars (@mkasztelnik)
- Service can have many owners, owners can see but not modify owned services (@mkasztelnik)
- Category counter cache takes into account service status (@mkasztelnik)

### Fixed
- Corrected typos in terms and conditions hint (@mkasztelnik)


## [1.0.0] - 2018-12-20

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
- Tabs to My profile view (@kmarszalek)
- 3 steps ordering (@mkasztelnik)
- New header & footer look (@kosmidma)
- Show 10, 20 or 30 services per page (@mkasztelnik)
- Go to order configuration step directly when there is only one offer (@mkasztelnik)
- Autoselect default project to open access service order and go directly to summary page (@mkasztelnik)
- Cannot order service when there is not offers (@mkasztelnik)
- Related services (@mkasztelnik)
- Service activate message (@mkasztelnik)
- Order steps layout (@mkasztelnik)
- Sidekiq for delayed jobs (@mkasztelnik)
- Admin administration panel stub with sidekiq monitoring and MP version (@mkasztelnik)
- Render root categories in page footer (@mkasztelnik)
- Use bootstrap cards to show service offers (@mkasztelnik)
- Add service logo (@mkasztelnik)
- Select affiliation on service order configuration page (@mkasztelnik)
- Styling of the 3rd step of the ordering process (@jswk)
- Add main navbar content and style it as in EOSC Portal (@jswk)
- Add real providers and missing entries in services in data.yml(@goreck888)
- Add known services relations in db/data.yml(@goreck888)
- Add filtering option to services (@michal-szostak)
- Optional additional information on configuration step (@martaswiatkowska)
- Research areas to service (@martaswiatkowska)
- Extend filtering for "dedicated for" field (@michal-szostak)
- Add sidekiq yaml configuration file (@wziajka)
- Add smtp configuration (@wziajka)
- Create new project on order configuration page (@mkasztelnik)
- Show alert for logged in user when there is not active affiliation (@mkasztelnik)
- Style ordered service view and remove mocked data (@mkasztelnik)
- Add logos to the services (@goreck888)
- User need to accept terms and conditions to order service (@mkasztelnik)
- Add new relic rpm (@mkasztelnik)
- Category hierarchical services count (@mkasztelnik)
- Show validation error when project is not selected for ordered service (@mkasztelnik)
- filter by status on my serices view (@martaswiatkowska)
- Simple form checks validation if conditions (@mkasztelnik)
- Clickable next order nav step (@mkasztelnik)
- Affiliation last step - consent (@martaswiatkowska)
- Multicheckbox widget to filters (providers & dedicated for) (@michal-szostak)
- Category tree in sidebar (@michal-szostak)
- Global filters to category view (@michal-szostak)
- Add offers to the services (@goreck888)
- Google analytics integration (@mkasztelnik)
- Friendly urls for categories and services (@mkasztelnik)
- Category select box to text searchbar (@michal-szostak)
- Fill order fields using predefined project fields (@mkasztelnik, @martaswiatkowska)
- Show offers sections only when there is more than 1 offer (@mkasztelnik)
- Dedicated ordering process for open access services (@mkasztelnik)
- Email signature and layout (@mkasztelnik, @abacz)
- Related Infrastructures and Platforms to filter section of services list (@martaswiatkowska)
- Related Infrastructures and Platforms to service details view (@kmarszalek)
- Technical parameters display in service offers (@michal-szostak)
- Add "All Services" link with services count above categories navigation in sidebar (@michal-szostak)
- Show "Go to the service" for catalog service (@mkasztelnik)
- Show affiliation info for project item (@jswk)
- Add a landing page for when affiliation is activated (@jswk)
- Favicon (@michal-szostak)
- Research area hierarchy (@mkasztelnik)
- Redirect user from `/affiliations` to `/profile` (@mkasztelnik)
- Service tags (@mkasztelnik)
- Customizable from email (@mkasztelnik)
- Flash fade out after 5 seconds (@mkasztelnik)
- Add new supported JIRA states (rejected, waiting for response) (@michal-szostak)
- ASSET_HOST and ASSET_PROTOCOL for mailer config (@kmarszalek)
- Additional field mapping to JIRA order (@michal-szostak)
- Possibility to setup RATE_AFTER_PERIOD ENV variable (@kmarszalek)
- Category field on create service view (@martaswiatkowska)
- Additional customer typologies fields for project_item and project (@martaswiatkowska)

### Changed
- Upgrade Sprockets gem to avoid CVE-2018-3760 vulnerability (@mkasztelnik)
- Fix and refactor seeds.rb to work properly (@goreck888)
- Update services and category list in data.yml (@goreck888)
- Update home view with static version (@kmarszalek)
- Upgrade service detail view (@kmarszalek)
- Rename `Order` to `ProjectItem` (@mkasztelnik)
- Rename `OrderChange` to `ProjectItemChange` (@mkasztelnik)
- Split backend for Service details view (@kmarszalek)
- Bootstrap improvements towards compliance with the guidelines (@jswk)
- Improve styling of affiliation list in profile and project list (@jswk)
- Deny to destroy an affiliation which is associated with a project item (@jswk)
- Styling of filters (@michal-szostak)
- Styling of ordering steps (@jarekzet, @michal-szostak)
- Remove description under "Services" header in services, add category description in categories (@michal-szostak)
- Reorder form parts in order/configuration (@michal-szostak)
- On project item view show order history in reversed order (@martaswiatkowska)
- Hide service offers on service about page if no offers are available (@michal-szostak)
- Rename "Some Header" in services' about page to "Documents" (@michal-szostak)
- Hide TODO Technical Parameters from service offer selection (@michal-szostak)
- Fields on Service entry to not be required (@kmarszalek)
- Link to webpage on project_item view (#martaswiatkowska)
- Url of terms and condition hint are taken from service.term_of_use_url (@martaswiatkowska)
- Platforms are not mandatory (@martaswiatkowska)
- Base URL for footer link updated to `https://eosc-portal.eu` (@mkasztelnik)
- Changed VO to Research groups in filters UI (@michal-szostak)
- Unify confirmation views - order, new affiliation, affiliation confirmations (@mkasztelnik)
- Improve wording of service, affiliation and project item mails (@jswk)
- Replace dedicated_for with target_group (@martaswiatkowska)
- Rating to three field form service_rating, order_rating and opinion (@kmarszalek)

### Deprecated

### Removed
- Remove default devise session routes, only logout remain (@mkasztelnik)

### Fixed
- Correctly expand affiliation accordions in profile (@jswk)
- Insert a line-break after button(s) in service header right panel (@jswk)
- Search by text from any view (@michal-szostak)
- Search does not preserve `page` query param (@michal-szostak)
- Multicheckbox does not take into account selected category when calculating available services (@michal-szostak)
- Change default sort order for services to name ascending (@michal-szostak)
- Open access services transition to "Done" state (@michal-szostak)
- Affiliations UI on small screens (@jarekzet)
- Support for Select type custom fields in JIRA (`CP-CustomerTypology`) (@michal-szostak)
- Input for tag_list for Service form in backoffice (@kmarszalek)

### Security
