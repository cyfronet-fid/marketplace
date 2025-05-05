# frozen_string_literal: true

FactoryBot.define do
  factory :jms_json_catalogue, class: String do
    skip_create
    transient do
      data do
        {
          resourceId: "a0dd4a3b-3809-4da9-847a-66736048762a",
          resourceType: "catalogue",
          resource: {
            metadata: {
              registeredBy: "Test user",
              registeredAt: 1_746_529_993_318,
              modifiedBy: "Test user",
              modifiedAt: 1_746_530_108_280,
              terms: ["test@user.com"],
              published: false
            },
            active: false,
            suspended: false,
            draft: false,
            identifiers: "",
            migrationStatus: "",
            loggingInfo: [
              {
                date: 1_746_529_993_318,
                userEmail: "test@user.com",
                userFullName: "Test user",
                userRole: "user",
                type: "onboard",
                comment: "",
                actionType: "registered"
              },
              {
                date: 1_746_530_108_281,
                userEmail: "test@user.com",
                userFullName: "Test user",
                userRole: "user",
                type: "update",
                comment: "needed to add another admin",
                actionType: "updated"
              }
            ],
            latestAuditInfo: "",
            latestOnboardingInfo: {
              date: 1_746_529_993_318,
              userEmail: "test@user.com",
              userFullName: "Test user",
              userRole: "user",
              type: "onboard",
              comment: "",
              actionType: "registered"
            },
            latestUpdateInfo: {
              date: 1_746_530_108_281,
              userEmail: "test@user.com",
              userFullName: "Test user",
              userRole: "user",
              type: "update",
              comment: "needed to add another admin",
              actionType: "updated"
            },
            status: "pending catalogue",
            auditState: "Not audited",
            transferContactInformation: nil,
            catalogue: {
              id: "test_dev_km",
              abbreviation: "test dev km",
              name: "test dev km",
              node: "",
              website: "http://website.org",
              legalEntity: true,
              legalStatus: "",
              hostingLegalEntity: "",
              inclusionCriteria: "https://google.pl",
              validationProcess: "https://google.pl",
              endOfLife: "winter",
              description: "description well written",
              scope: "Thematic catalogue (specify thematic area), National catalogue (specify Country), etc.",
              logo: "https://www.google.pl",
              multimedia: [],
              scientificDomains: [],
              tags: [],
              location: {
                streetNameAndNumber: "Nawojki 11",
                postalCode: "30-950",
                city: "Krakow",
                region: "Województwoo",
                country: "PL"
              },
              mainContact: {
                firstName: "Test",
                lastName: "user",
                email: "a.user@cyfronet.pl",
                phone: nil,
                position: nil
              },
              publicContacts: [
                { firstName: nil, lastName: nil, email: "a.user@cyfronet.pl", phone: nil, position: nil }
              ],
              participatingCountries: ["PL"],
              affiliations: [],
              networks: [],
              users: [
                {
                  id: "94163559-71a4-4ba3-94c8-322681c8409b@myaccessid.org",
                  email: "test@user.com",
                  name: "Test",
                  surname: "user"
                },
                { id: nil, email: "j.doe@cyfronet.pl", name: "Jane", surname: "Doe" }
              ]
            },
            id: "may_2025_sfd"
          },
          payloadFormat: "json",
          previous: {
            metadata: {
              registeredBy: "Test user",
              registeredAt: "1746529993318",
              modifiedBy: "Test user",
              modifiedAt: "1746530108280",
              terms: ["test@user.com"],
              published: false
            },
            active: false,
            suspended: false,
            draft: false,
            identifiers: "",
            migrationStatus: "",
            loggingInfo: [
              {
                date: "1746529993318",
                userEmail: "test@user.com",
                userFullName: "Test user",
                userRole: "user",
                type: "onboard",
                comment: "",
                actionType: "registered"
              },
              {
                date: "1746530108281",
                userEmail: "test@user.com",
                userFullName: "Test user",
                userRole: "user",
                type: "update",
                comment: "needed to add another admin",
                actionType: "updated"
              }
            ],
            latestAuditInfo: "",
            latestOnboardingInfo: {
              date: "1746529993318",
              userEmail: "test@user.com",
              userFullName: "Test user",
              userRole: "user",
              type: "onboard",
              comment: "",
              actionType: "registered"
            },
            latestUpdateInfo: {
              date: "1746530108281",
              userEmail: "test@user.com",
              userFullName: "Test user",
              userRole: "user",
              type: "update",
              comment: "needed to add another admin",
              actionType: "updated"
            },
            status: "pending catalogue",
            auditState: "Not audited",
            transferContactInformation: nil,
            catalogue: {
              id: "may_2025_sfd",
              abbreviation: "may 2025 sfd",
              name: "06.05.2025",
              node: "",
              website: "http://website.org",
              legalEntity: false,
              legalStatus: "",
              hostingLegalEntity: "",
              inclusionCriteria: "https://google.pl",
              validationProcess: "https://google.pl",
              endOfLife: "winter",
              description: "description well written",
              scope: "Thematic catalogue (specify thematic area), National catalogue (specify Country), etc.",
              logo: "https://www.google.pl",
              multimedia: [],
              scientificDomains: [],
              tags: [],
              location: {
                streetNameAndNumber: "Śniadeckich",
                postalCode: "55-565",
                city: "tarnow",
                region: "Województwoo",
                country: "PL"
              },
              mainContact: {
                firstName: "Test",
                lastName: "user",
                email: "a.user@cyfronet.pl",
                phone: "0048513542052",
                position: "fsdfds"
              },
              publicContacts: [
                {
                  firstName: "Test",
                  lastName: "user",
                  email: "a.user@cyfronet.pl",
                  phone: "0048513542052",
                  position: "sdfdsfds"
                }
              ],
              participatingCountries: ["PL"],
              affiliations: [],
              networks: [],
              users: [
                {
                  id: "94163559-71a4-4ba3-94c8-322681c8409b@myaccessid.org",
                  email: "test@user.com",
                  name: "Test",
                  surname: "user"
                },
                { id: "", email: "j.doe@cyfronet.pl", name: "Jane", surname: "doe" }
              ]
            },
            id: "may_2025_sfd"
          }
        }
      end
    end
    initialize_with { data.to_json }
  end
end
