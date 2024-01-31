# frozen_string_literal: true

FactoryBot.define do
  factory :jira_webhook_response, class: Hash do
    skip_create
    transient do
      sequence(:id)
      timestamp { 1_525_698_237_764 }
      issue_id { 0 }
      issue_status { 4 }
      voucher_id_from { nil }
      voucher_id_to { nil }
      message { "Just in time for AtlasCamp!" }
      request_type { "jira:issue_updated" }
      comment do
        {
          self: "https://jira.atlassian.com/rest/api/2/issue/10148/comment/252789",
          id: "252789",
          author: {
            self: "https://jira.atlassian.com/rest/api/2/user?username=brollins",
            name: "brollins",
            emailAddress: "bryansemail@atlassian.com",
            avatarUrls: {
              "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
              "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
            },
            displayName: "Bryan Rollins [Atlassian]",
            active: true
          },
          body: "Just in time for AtlasCamp!",
          updateAuthor: {
            self: "https://jira.atlassian.com/rest/api/2/user?username=brollins",
            name: "brollins",
            emailAddress: "brollins@atlassian.com",
            avatarUrls: {
              "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
              "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
            },
            displayName: "Bryan Rollins [Atlassian]",
            active: true
          },
          created: "2011-06-07T10:31:26.805-0500",
          updated: "2011-06-07T10:31:26.805-0500"
        }
      end

      changelog do
        {
          toString: "A new summary.",
          to: issue_status,
          fromString: "What is going on here?????",
          from: 0,
          fieldtype: "jira",
          field: "status"
        }
      end
    end

    trait :voucher_id_change do
      transient do
        changelog do
          {
            toString: voucher_id_to,
            to: nil,
            fromString: voucher_id_from,
            from: nil,
            fieldtype: "custom",
            field: "CP-VoucherID"
          }
        end
      end
    end

    trait :comment_update do
      transient do
        request_type { "comment_updated" }
        comment do
          {
            self: "https://jira.atlassian.com/rest/api/2/issue/10148/comment/252789",
            id: id,
            author: {
              self: "https://jira.atlassian.com/rest/api/2/user?username=brollins",
              name: "brollins",
              emailAddress: "bryansemail@atlassian.com",
              avatarUrls: {
                "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
                "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
              },
              displayName: "Bryan Rollins [Atlassian]",
              active: true
            },
            body: message,
            updateAuthor: {
              self: "https://jira.atlassian.com/rest/api/2/user?username=brollins",
              name: "brollins",
              emailAddress: "brollins@atlassian.com",
              avatarUrls: {
                "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
                "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
              },
              displayName: "Bryan Rollins [Atlassian]",
              active: true
            },
            created: "2011-06-07T10:31:26.805-0500",
            updated: "2011-06-07T10:31:26.805-0500"
          }
        end
      end
    end

    initialize_with do
      next(
        {
          id: id,
          timestamp: timestamp,
          issue: {
            id: issue_id,
            self: "https://jira.atlassian.com/rest/api/2/issue/99291",
            key: "JRA-20002",
            fields: {
              summary: "I feel the need for speed",
              created: "2009-12-16T23:46:10.612-0600",
              description: "Make the issue nav load 10x faster",
              labels: %w[UI dialogue move],
              priority: "Minor"
            }
          },
          user: {
            self: "https://jira.atlassian.com/rest/api/2/user?username=brollins",
            name: "brollins",
            key: "brollins",
            emailAddress: "bryansemail at atlassian dot com",
            avatarUrls: {
              "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
              "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
            },
            displayName: "Bryan Rollins [Atlassian]",
            active: "true"
          },
          changelog: {
            items: [changelog],
            id: 10_124
          },
          comment: comment,
          webhookEvent: request_type
        }
      )
    end
  end
end
