# frozen_string_literal: true

require "jira/setup"
require "jira/console_checker"
require "jira/client"

namespace :jira do
  desc "Check JIRA configuration"

  task check: :environment do
    Jira::ConsoleChecker.new.check
  end

  task setup: :environment do
    Jira::Setup.new.call
  end

  task migrate_projects: :environment do
    Jira::ProjectMigrator.new.call
  end
end
