# frozen_string_literal: true

namespace :openapi do
  desc "Write all the OpenAPI documents of the API to one file that has no references to other files"
  task bundle: :environment do
    root = Rails.root.join("swagger/v1")
    root.join("spec.json").write("#{JSON.pretty_generate(Api::V1::OpenapiBundle.call(root))}\n")
  end
end

# The rswag tasks are available only in the development and test environments.
if Rake::Task.task_defined?("rswag:specs:swaggerize")
  Rake::Task["rswag:specs:swaggerize"].enhance { Rake::Task["openapi:bundle"].invoke }
end
