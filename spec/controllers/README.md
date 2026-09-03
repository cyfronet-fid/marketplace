# Controller specs are deprecated — don't add new ones

`rspec-rails` stopped bundling controller specs (`type: :controller`) by
default back in RSpec 3.5 for Rails 5 support (2016):
<https://rspec.info/blog/2016/07/rspec-3-5-has-been-released/#rails-support-for-rails-5>.
They still work here because `rails-controller-testing` is in the Gemfile,
but the RSpec/Rails teams' guidance has stood for years: use request specs
instead. Controller specs bypass the router and the full middleware stack,
so they don't catch routing mistakes, and several here call private methods
directly (`controller.send(:some_private_method)`), coupling the test to
implementation rather than to the actual HTTP behavior users depend on.

## Current state (8 files)

Not all of these are "endpoint" tests, and coverage against the equivalent
request spec is uneven:

| File | What it actually tests | Request-spec equivalent |
|---|---|---|
| `concerns/recommendable_spec.rb` | `Recommendable` concern via `ApplicationController` | n/a — concern unit test |
| `concerns/searchable_spec.rb` | `Searchable` concern via `ApplicationController` | n/a — concern unit test |
| `concerns/sortable_spec.rb` | `Sortable` concern via a fake controller class | n/a — concern unit test |
| `concerns/tourable_spec.rb` | `Tourable` concern | n/a — concern unit test |
| `services/choose_offers_controller_spec.rb` | `Services::ChooseOffersController#show`/`#update` via real dispatch | **Yes** — `spec/requests/services/application_controller_spec.rb` hits the same `choose_offer` route |
| `user_action_controller_spec.rb` | `UserActionController#create` via real dispatch | **None found** |
| `api/v1/search/services_controller_facets_spec.rb` | private `#facets` method directly, mocked ES response | Partial — `spec/requests/api/v1/search/services_controller_spec.rb` exercises `facets` through the real endpoint, but with different (integration-level) intent |
| `federation/services_controller_active_filters_spec.rb` | private `#active_filters` method directly | **None found** |

`auth_mock_controller_spec.rb` has been replaced by
`spec/requests/users/auth_mock_controller_spec.rb` and removed from this
directory — the route it exercises (`users/login`) is only drawn when
`Rails.env.development? && Mp::Application.config.auth_mock`, so the request
spec draws it for the duration of each example instead.

So only one controller (`Services::ChooseOffersController`) has genuine
duplicate coverage today. The other four concern specs aren't duplicating
anything since they test shared modules, not endpoints. But
`UserActionController#create` and `Federation::ServicesController#active_filters`
still have **no request-spec coverage at all** — deleting those controller
specs outright would lose real signal, not just remove duplication.

## Recommendation

Don't delete this directory in one pass. For each file: write (or confirm)
an equivalent request spec first, verify it covers what the controller spec
covers, then remove the `type: :controller` version. The concern specs
(`recommendable`, `searchable`, `sortable`, `tourable`) aren't endpoint
tests and can likely stay as plain unit tests, just not under `spec/controllers`
using the controller-spec DSL.
