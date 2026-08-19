# Agent conventions for this repo

Ruby 3.3, Rails 7.2. RSpec (`rspec-rails`) for tests, not Minitest. Style is enforced by RuboCop with `prettier`'s inherited config (`.rubocop.yml`) — don't flag pure style/formatting, that's covered separately.

## Architecture patterns to know

- **Authorization**: Pundit policies in `app/policies/`, one per model, method names like `*_managed_by_user?`. Controllers call `authorize`/`policy_scope`; don't suggest ad-hoc `current_user ==` checks where a policy already exists.
- **Object-oriented design**: code should follow OOP/SOLID — single-responsibility objects over procedural logic scattered across models and controllers. Flag violations (god objects, mixed responsibilities, logic that belongs in a collaborator) as design issues, not just style.
- **Models**: all inherit from `ApplicationRecord` (`app/models/application_record.rb`). Business logic beyond validations/associations belongs in `app/services/`, not in models — flag fat models, not fat controllers.
- **Concerns**: shared model/controller behavior lives in `app/models/concerns/` and `app/controllers/concerns/`. Services are the preferred pattern going forward — when a diff touches logic that currently lives in a concern, suggest extracting it to a service rather than adding to the concern. Don't flag an existing concern just for being a concern; check `app/services/` before suggesting a new extraction that may already exist there.
- **API responses**: `app/serializers/`, built on `active_model_serializers`, which is unmaintained. Don't suggest expanding usage of it — new serialization work should move toward a maintained alternative incrementally. Flag any change that deepens dependence on the old gem.
- **Background work**: `app/jobs/`.

## When reviewing a diff

- Diffs are Rails-app changes touching ActiveRecord models, Pundit policies, services, or RSpec specs most often — weight review effort there over views/assets.
- Migrations (`db/migrate/`) are append-only and irreversible once merged — flag anything destructive (dropping columns/tables, non-nullable additions without a default) as high-severity, not a style note.
- If a method changes on a model or policy, check whether it has RSpec coverage (`spec/` mirrors `app/`); flag missing specs for behavior changes, not for trivial getters.
