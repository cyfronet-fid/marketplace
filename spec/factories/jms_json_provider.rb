# frozen_string_literal: true

FactoryBot.define do
  factory :jms_json_provider, class: String do
    skip_create
    transient do
      data do
        {
          resourceId: "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          resourceType: "provider",
          resource: {
            active: true,
            metadata: {
              modifiedAt: 1_613_193_818_577,
              modifiedBy: "Gaweł Porczyca",
              registeredAt: 1_601_623_322_996,
              registeredBy: "Gaweł Porczyca",
              terms: %w[grck@gmail.com ar@test.com]
            },
            status: "approved",
            provider: {
              alternativeIdentifiers: [],
              abbreviation: "CYFRONET",
              affiliations: %w[asdf test],
              areasOfActivity: ["provider_area_of_activity-applied_research"],
              certifications: %w[ISO-345 ASE/EBU-2008],
              description: "Test provider for jms queue",
              esfriDomains: ["provider_esfri_domain-energy"],
              esfriType: "provider_esfri_type-landmark",
              hostingLegalEntity: "cyfronet",
              id: "eosc.cyfronet",
              catalogueId: "eosc",
              legalEntity: true,
              legalStatus: "provider_legal_status-public_legal_entity",
              lifeCycleStatus: "provider_life_cycle_status-operational",
              location: {
                city: "Kraków",
                country: "PL",
                postalCode: "30-950",
                region: "Lesser Poland",
                streetNameAndNumber: "ul. Nawojki 11"
              },
              logo: "http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg",
              mainContact: {
                email: "john@doe.pl",
                firstName: "John",
                lastName: "Doe"
              },
              merilScientificDomains: [
                {
                  merilScientificDomain: "provider_meril_scientific_domain-other",
                  merilScientificSubdomain: "provider_meril_scientific_subdomain-other-other"
                }
              ],
              multimedia: [],
              name: "Test-Cyfronet #3",
              nationalRoadmaps: %w[test test2],
              networks: ["provider_network-aegis"],
              participatingCountries: %w[BB AT],
              publicContacts: [{ email: "g.porczyca@cyfronet.pl" }],
              scientificDomains: [
                {
                  scientificDomain: "scientific_domain-generic",
                  scientificSubdomain: "scientific_subdomain-generic-generic"
                }
              ],
              societalGrandChallenges: ["provider_societal_grand_challenge-secure_societies"],
              structureTypes: ["provider_structure_type-mobile"],
              tags: %w[tag test cyfro],
              users: [{ email: "grck@qmail.com", name: "Gaweł", surname: "Porczyca" }],
              website: "http://www.cyfronet.pl"
            },
            payloadFormat: "json"
          }
        }
      end
    end
    initialize_with { data.to_json }
  end
  factory :jms_json_draft_provider, class: String do
    skip_create
    transient do
      data do
        {
          resourceId: "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          resourceType: "provider",
          resource: {
            active: false,
            latestOnboardingInfo: {
              actionType: "approved"
            },
            metadata: {
              modifiedAt: 1_613_193_818_577,
              modifiedBy: "Gaweł Porczyca",
              registeredAt: 1_601_623_322_996,
              registeredBy: "Gaweł Porczyca",
              terms: %w[grck@gmail.com ar@test.com]
            },
            status: "approved",
            provider: {
              abbreviation: "CYFRONET",
              alternativeIdentifiers: [],
              affiliations: %w[asdf test],
              areasOfActivity: ["provider_area_of_activity-applied_research"],
              certifications: %w[ISO-345 ASE/EBU-2008],
              description: "Test provider for jms queue</tns:description>",
              esfriDomains: ["provider_esfri_domain-energy"],
              esfriType: "provider_esfri_type-landmark",
              hostingLegalEntity: "cyfronet",
              id: "eosc.cyfronet",
              catalogueId: "eosc",
              legalEntity: true,
              legalStatus: "provider_legal_status-public_legal_entity",
              lifeCycleStatus: "provider_life_cycle_status-operational",
              location: {
                city: "Kraków",
                country: "PL",
                postalCode: "30-950",
                region: "Lesser Poland",
                streetNameAndNumber: "ul. Nawojki 11"
              },
              logo: "http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg",
              mainContact: {
                email: "john@doe.pl",
                firstName: "John",
                lastName: "Doe"
              },
              merilScientificDomains: [
                {
                  merilScientificDomain: "provider_meril_scientific_domain-other",
                  merilScientificSubdomain: "provider_meril_scientific_subdomain-other-other"
                }
              ],
              multimedia: [],
              name: "Test-Cyfronet #3",
              nationalRoadmaps: %w[test test2],
              networks: ["provider_network-aegis"],
              participatingCountries: %w[BB AT],
              publicContacts: [{ email: "g.porczyca@cyfronet.pl" }],
              scientificDomains: [
                {
                  scientificDomain: "scientific_domain-generic",
                  scientificSubdomain: "scientific_subdomain-generic-generic"
                }
              ],
              societalGrandChallenges: ["provider_societal_grand_challenge-secure_societies"],
              structureTypes: ["provider_structure_type-mobile"],
              tags: %w[tag test cyfro],
              users: [{ email: "grck@qmail.com", id: nil, name: "Gaweł", surname: "Porczyca" }],
              website: "http://www.cyfronet.pl"
            },
            payloadFormat: "json"
          }
        }
      end
    end
    initialize_with { data.to_json }
  end
  factory :jms_json_rejected_provider, class: String do
    skip_create
    transient do
      data do
        {
          resourceId: "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          resourceType: "provider",
          resource: {
            active: false,
            suspended: false,
            latestOnboardingInfo: {
              actionType: "rejected"
            },
            metadata: {
              modifiedAt: 1_613_193_818_577,
              modifiedBy: "Gaweł Porczyca",
              registeredAt: 1_601_623_322_996,
              registeredBy: "Gaweł Porczyca",
              terms: %w[grck@gmail.com ar@test.com]
            },
            status: "approved",
            provider: {
              alternativeIdentifiers: [],
              abbreviation: "CYFRONET",
              affiliations: %w[asdf test],
              areasOfActivity: ["provider_area_of_activity-applied_research"],
              certifications: %w[ISO-345 ASE/EBU-2008],
              description: "Test provider for jms queue",
              esfriDomains: ["provider_esfri_domain-energy"],
              esfriType: "provider_esfri_type-landmark",
              hostingLegalEntity: "cyfronet",
              id: "eosc.cyfronet",
              catalogueId: "eosc",
              legalEntity: true,
              legalStatus: "provider_legal_status-public_legal_entity",
              lifeCycleStatus: "provider_life_cycle_status-operational",
              location: {
                city: "Kraków",
                country: "PL",
                postalCode: "30-950",
                region: "Lesser Poland",
                streetNameAndNumber: "ul. Nawojki 11"
              },
              logo: "http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg",
              mainContact: {
                email: "john@doe.pl",
                firstName: "John",
                lastName: "Doe"
              },
              merilScientificDomains: [
                {
                  merilScientificDomain: "provider_meril_scientific_domain-other",
                  merilScientificSubdomain: "provider_meril_scientific_subdomain-other-other"
                }
              ],
              multimedia: [],
              name: "Test-Cyfronet #3",
              nationalRoadmaps: %w[test test2],
              networks: ["provider_network-aegis"],
              participatingCountries: %w[BB AT],
              publicContacts: [email: "g.porczyca@cyfronet.pl"],
              scientificDomains: [
                {
                  scientificDomain: "scientific_domain-generic",
                  scientificSubdomain: "scientific_subdomain-generic-generic"
                }
              ],
              societalGrandChallenges: ["provider_societal_grand_challenge-secure_societies"],
              structureTypes: ["provider_structure_type-mobile"],
              tags: %w[tag test cyfro],
              users: [{ email: "grck@qmail.com", id: nil, name: "Gaweł", surname: "Porczyca" }],
              website: "http://www.cyfronet.pl"
            },
            payloadFormat: "json"
          }
        }
      end
    end
    initialize_with { data.to_json }
  end
end
