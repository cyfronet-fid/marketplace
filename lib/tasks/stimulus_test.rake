# frozen_string_literal: true

task default: %w[test:system test test:js]

namespace :test do
  task :js do
    sh "yarn test"
  end
end
