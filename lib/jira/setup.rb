# frozen_string_literal: true

module Jira
  class Setup
    def initialize(client = Jira::Client.new)
      @client = client
    end

    def call
      @client.mp_project
      puts "Project #{@client.jira_project_key} already exists"
    rescue JIRA::HTTPError => e
      if e.response.code == "404"
        p = @client.Project.build
        unless p.save(
                 key: @client.jira_project_key,
                 name: @client.jira_project_key,
                 projectTemplateKey: "com.atlassian.jira-core-project-templates:jira-core-project-management",
                 projectTypeKey: "business",
                 lead: @client.jira_config["username"]
               )
          abort("ERROR: Could not create project")
        end
        puts "Created project #{@client.jira_project_key}"
      else
        abort("ERROR: Could not find project [#{e.response.code}]")
      end
    end
  end
end
