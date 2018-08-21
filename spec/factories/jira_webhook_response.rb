# frozen_string_literal: true


FactoryBot.define do
  factory :jira_webhook_response, class: Hash do
    skip_create
    transient do
      sequence(:id)
      timestamp 1525698237764
      issue_id 0
      issue_status 4
    end

    initialize_with do
      next {
        "id":           id,
        "timestamp":    timestamp,
        "issue": {
            "id":     issue_id,
            "self":   "https://jira.atlassian.com/rest/api/2/issue/99291",
            "key":    "JRA-20002",
            "fields": {
                "summary":     "I feel the need for speed",
                "created":     "2009-12-16T23:46:10.612-0600",
                "description": "Make the issue nav load 10x faster",
                "labels":      ["UI", "dialogue", "move"],
                "priority":    "Minor"
            }
        },
        "user":         {
            "self":         "https://jira.atlassian.com/rest/api/2/user?username=brollins",
            "name":         "brollins",
            "key":          "brollins",
            "emailAddress": "bryansemail at atlassian dot com",
            "avatarUrls":   {
                "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
                "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
            },
            "displayName":  "Bryan Rollins [Atlassian]",
            "active":       "true"
        },
        "changelog":    {
            "items": [
                         {
                             "toString":   "A new summary.",
                             "to":         issue_status,
                             "fromString": "What is going on here?????",
                             "from":       0,
                             "fieldtype":  "jira",
                             "field":      "status"
                         }
                     ],
            "id":    10124
        },
        "comment":      {
            "self":         "https://jira.atlassian.com/rest/api/2/issue/10148/comment/252789",
            "id":           "252789",
            "author":       {
                "self":         "https://jira.atlassian.com/rest/api/2/user?username=brollins",
                "name":         "brollins",
                "emailAddress": "bryansemail@atlassian.com",
                "avatarUrls":   {
                    "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
                    "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
                },
                "displayName":  "Bryan Rollins [Atlassian]",
                "active":       true
            },
            "body":         "Just in time for AtlasCamp!",
            "updateAuthor": {
                "self":         "https://jira.atlassian.com/rest/api/2/user?username=brollins",
                "name":         "brollins",
                "emailAddress": "brollins@atlassian.com",
                "avatarUrls":   {
                    "16x16": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10605",
                    "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10605"
                },
                "displayName":  "Bryan Rollins [Atlassian]",
                "active":       true
            },
            "created":      "2011-06-07T10:31:26.805-0500",
            "updated":      "2011-06-07T10:31:26.805-0500"
        },
        "webhookEvent": "jira:issue_updated"
      }
    end
  end
end
