# frozen_string_literal: true

require "jira/client"
require "colorize"

namespace :jira do
  desc "Check JIRA configuration"
  error = false

  def ok!
    print " OK".green << "\n"
  end

  task check: :environment do
    class UnauthorizedError < StandardError; end
    class CanNotCreateIssueError < StandardError; end
    class CanNotUpdateIssueError < StandardError; end
    class CanNotPostCommentError < StandardError; end
    class CanNotDeleteIssueError < StandardError; end

    client = Jira::Client.new

    begin
      begin
        print "Checking access..."
        client.Project.all
        ok!
      rescue JIRA::HTTPError => e
        if e.response.code == "401"
          raise UnauthorizedError.new
        else
          STDERR.puts "\nERROR #{e.body}"
        end
      end

      begin
        print "Checking issue type presence..."
        client.mp_issue_type
        ok!
      rescue JIRA::HTTPError => e
        error = true
        if e.response.code == "404"
          STDERR.puts "\nERORR: It seems that ticket with id #{JIRA_ISSUE_TYPE_ID} does not exist, make sure to add existing issue type into configuration"
        else
          STDERR.puts "\nERORR: Unexpected error ocurred: #{e}"
        end
      end


      begin
        print "Checking project existence..."
        client.mp_project
        ok!
      rescue JIRA::HTTPError => e
        error = true
        if e.response.code == "404"
          STDERR.puts "\nERORR: Could not find project #{JIRA_PROJECT_KEY}, make sure it exists and user #{JIRA_OPTIONS[:username]} has access to it"
        else
          STDERR.puts "\nERORR: Unexpected error ocurred: #{e}"
        end
        # following tests require project to exist, if it does not return
        next
      end

      begin
        issue_type = client.mp_issue_type

        issue_name = issue_type.attrs["name"]

        puts "Trying to manipulate issue..."
        print "  - create issue..."

        issue = client.Issue.build
        unless issue.save(fields: { summary: "TEST TICKET, TO CHECK WHETHER JIRA INTEGRATION WORKS",
                                   project: { key: client.jira_project_key },
                                   issuetype: { id: client.jira_issue_type_id } })
          raise CanNotCreateIssueError.new("Could not create issue in project: " + "#{client.jira_project_key}".yellow + " and issuetype: " + "#{client.jira_issue_type_id}".yellow + " (name: " + "#{issue_name}".yellow + ")")
        end
        ok!
        print "  - update issue ..."
        unless issue.save(fields: { description: "TEST DESCRIPTION" })
          raise CanNotUpdateIssueError.new("Could not update issue description")
        end
        ok!
        print "  - add comment to issue ..."
        c = issue.comments.build
        unless c.save(body: "TEST QUESTION")
          raise CanNotPostCommentError.new("Could not post comment")
        end

        begin
          ok!
          print "  - delete issue ..."
          issue.delete
          ok!
        rescue JIRA::HTTPError => e
          if e.response.code == "403"
            print " FAIL\n".red
            STDERR.puts "    WARNING".yellow + ": Could not delete issue #{issue.key}, this is " + "not critical".bold + " but you will have to delete it manually from the project"
          else
            raise CanNotDeleteIssueError.new("Could not delete issue, reason: #{e.response.code}: #{e.response.body}")
          end
        end
      end

    rescue Errno::ECONNREFUSED
      error = true
      STDERR.puts "\nERORR: Could not connect to JIRA: #{ client.JIRA_OPTIONS[:site] }"

    rescue UnauthorizedError
      error = true
      STDERR.puts "\nERROR: Could not authenticate #{client.JIRA_OPTIONS[:username]} on #{client.JIRA_OPTIONS[:site]}"

    rescue CanNotCreateIssueError, CanNotUpdateIssueError, CanNotDeleteIssueError, CanNotPostCommentError => e
      error = true
      STDERR.puts "\n  - ERROR: #{e.message}"

    rescue => e
      error = true
      STDERR.puts "\nERROR: Unexpected error ocurred #{e.message}\n\n#{e.backtrace}"
    end

    if error
      abort("jira:check exited with errors")
    end
  end

  task setup: :environment do
    client = Jira::Client.new

    begin
      p = client.mp_project
      puts "Project #{client.jira_project_key} already exists"
    rescue JIRA::HTTPError => e
      if e.response.code == "404"
        p = client.Project.build
        unless p.save(key: client.jira_project_key, name: client.jira_project_key,
                      projectTemplateKey: "com.atlassian.jira-core-project-templates:jira-core-project-management",
                      projectTypeKey: "business", lead: client.JIRA_OPTIONS[:username])
          abort("ERROR: Could not create project")
        end
        puts "Created project #{client.jira_project_key}"
      end
    end

  end
end
