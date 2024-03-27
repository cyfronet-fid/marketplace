# frozen_string_literal: true

FactoryBot.define do
  factory :jms_xml_provider, class: String do
    skip_create
    initialize_with do
      next(
        {
          "resourceId" => "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          "resourceType" => "provider",
          "resource" =>
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
              "<tns:providerBundle xmlns:tns=\"http://einfracentral.eu\">" \
              "<tns:active>true</tns:active>" \
              "<tns:metadata>" \
              "<tns:modifiedAt>1613193818577</tns:modifiedAt>" \
              "<tns:modifiedBy>Gaweł Porczyca</tns:modifiedBy>" \
              "<tns:registeredAt>1601623322996</tns:registeredAt>" \
              "<tns:registeredBy>Gaweł Porczyca</tns:registeredBy>" \
              "<tns:terms>" \
              "<tns:term>grck@gmail.com</tns:term>" +
              "<tns:term>ar@test.com</tns:term>" \
                "</tns:terms>" \
                "</tns:metadata>" +
              "<tns:status>approved</tns:status>" \
                "<tns:provider>" \
                "<tns:abbreviation>CYFRONET</tns:abbreviation>" \
                "<tns:ppid></tns:ppid>" \
                "<tns:affiliations>" \
                "<tns:affiliation>asdf</tns:affiliation>" \
                "<tns:affiliation>test</tns:affiliation></tns:affiliations>" \
                "<tns:areasOfActivity>" \
                "<tns:areaOfActivity>provider_area_of_activity-applied_research</tns:areaOfActivity>" \
                "</tns:areasOfActivity>" +
              "<tns:certifications>" \
                "<tns:certification>ISO-345</tns:certification>" \
                "<tns:certification>ASE/EBU-2008</tns:certification>" \
                "</tns:certifications>" \
                "<tns:description>Test provider for jms queue</tns:description>" \
                "<tns:esfriDomains>" \
                "<tns:esfriDomain>provider_esfri_domain-energy</tns:esfriDomain>" \
                "</tns:esfriDomains>" \
                "<tns:esfriType>provider_esfri_type-landmark</tns:esfriType>" \
                "<tns:hostingLegalEntity>cyfronet</tns:hostingLegalEntity>" \
                "<tns:id>eosc.cyfronet</tns:id>" \
                "<tns:catalogueId>eosc</tns:catalogueId>" \
                "<tns:legalEntity>true</tns:legalEntity>" \
                "<tns:legalStatus>provider_legal_status-public_legal_entity</tns:legalStatus>" \
                "<tns:lifeCycleStatus>provider_life_cycle_status-operational</tns:lifeCycleStatus>" \
                "<tns:location>" \
                "<tns:city>Kraków</tns:city>" \
                "<tns:country>PL</tns:country>" \
                "<tns:postalCode>30-950</tns:postalCode>" \
                "<tns:region>Lesser Poland</tns:region>" \
                "<tns:streetNameAndNumber>ul. Nawojki 11</tns:streetNameAndNumber>" \
                "</tns:location>" \
                "<tns:logo>http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg</tns:logo>" \
                "<tns:mainContact>" \
                "<tns:email>john@doe.pl</tns:email>" \
                "<tns:firstName>John</tns:firstName>" \
                "<tns:lastName>Doe</tns:lastName>" +
              "</tns:mainContact>" \
                "<tns:merilScientificDomains>" \
                "<tns:merilScientificDomain>" \
                "<tns:merilScientificDomain>provider_meril_scientific_domain-other</tns:merilScientificDomain>" \
                "<tns:merilScientificSubdomain>provider_meril_scientific_subdomain-other-other</tns:merilScientificSubdomain>" \
                "</tns:merilScientificDomain>" +
              "</tns:merilScientificDomains>" \
                "<tns:multimedia/>" \
                "<tns:name>Test-Cyfronet #3</tns:name>" \
                "<tns:nationalRoadmaps>" \
                "<tns:nationalRoadmap>test</tns:nationalRoadmap>" \
                "<tns:nationalRoadmap>test2</tns:nationalRoadmap>" \
                "</tns:nationalRoadmaps>" +
              "<tns:networks>" \
                "<tns:network>provider_network-aegis</tns:network>" \
                "</tns:networks>" \
                "<tns:participatingCountries>" \
                "<tns:participatingCountry>BB</tns:participatingCountry>" \
                "<tns:participatingCountry>AT</tns:participatingCountry>" \
                "</tns:participatingCountries>" \
                "<tns:publicContacts>" \
                "<tns:publicContact><tns:email>g.porczyca@cyfronet.pl</tns:email></tns:publicContact>" \
                "</tns:publicContacts>" +
              "<tns:scientificDomains>" \
                "<tns:scientificDomain>" \
                "<tns:scientificDomain>scientific_domain-generic</tns:scientificDomain>" \
                "<tns:scientificSubdomain>scientific_subdomain-generic-generic</tns:scientificSubdomain>" \
                "</tns:scientificDomain>" +
              "</tns:scientificDomains>" \
                "<tns:societalGrandChallenges>" \
                "<tns:societalGrandChallenge>provider_societal_grand_challenge-secure_societies</tns:societalGrandChallenge>" \
                "</tns:societalGrandChallenges>" \
                "<tns:structureTypes>" \
                "<tns:structureType>provider_structure_type-mobile</tns:structureType>" \
                "</tns:structureTypes>" \
                "<tns:tags>" + "<tns:tag>tag</tns:tag>" +
              "<tns:tag>test</tns:tag>" \
                "<tns:tag>cyfro</tns:tag>" \
                "</tns:tags>" + "<tns:users>" +
              "<tns:user>" \
                "<tns:email>grck@qmail.com</tns:email>" \
                "<tns:id></tns:id>" + "<tns:name>Gaweł</tns:name>" +
              "<tns:surname>Porczyca</tns:surname>" \
                "</tns:user>" \
                "</tns:users>" +
              "<tns:website>http://www.cyfronet.pl</tns:website>" \
                "</tns:provider>" \
                "</tns:providerBundle>",
          "payloadFormat" => "xml"
        }
      )
    end
  end
  factory :jms_xml_draft_provider, class: String do
    initialize_with do
      next(
        {
          "resourceId" => "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          "resourceType" => "provider",
          "resource" =>
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
              "<tns:providerBundle xmlns:tns=\"http://einfracentral.eu\">" \
              "<tns:active>false</tns:active>" \
              "<tns:latestOnboardingInfo>" \
              "<tns:actionType>approved</tns:actionType>" \
              "</tns:latestOnboardingInfo>" \
              "<tns:metadata>" \
              "<tns:modifiedAt>1613193818577</tns:modifiedAt>" \
              "<tns:modifiedBy>Gaweł Porczyca</tns:modifiedBy>" \
              "<tns:registeredAt>1601623322996</tns:registeredAt>" \
              "<tns:registeredBy>Gaweł Porczyca</tns:registeredBy>" \
              "<tns:terms>" \
              "<tns:term>grck@gmail.com</tns:term>" +
              "<tns:term>ar@test.com</tns:term>" \
                "</tns:terms>" \
                "</tns:metadata>" +
              "<tns:status>approved</tns:status>" \
                "<tns:provider>" \
                "<tns:abbreviation>CYFRONET</tns:abbreviation>" \
                "<tns:ppid></tns:ppid>" \
                "<tns:affiliations>" \
                "<tns:affiliation>asdf</tns:affiliation>" \
                "<tns:affiliation>test</tns:affiliation></tns:affiliations>" \
                "<tns:areasOfActivity>" \
                "<tns:areaOfActivity>provider_area_of_activity-applied_research</tns:areaOfActivity>" \
                "</tns:areasOfActivity>" +
              "<tns:certifications>" \
                "<tns:certification>ISO-345</tns:certification>" \
                "<tns:certification>ASE/EBU-2008</tns:certification>" \
                "</tns:certifications>" \
                "<tns:description>Test provider for jms queue</tns:description>" \
                "<tns:esfriDomains>" \
                "<tns:esfriDomain>provider_esfri_domain-energy</tns:esfriDomain>" \
                "</tns:esfriDomains>" \
                "<tns:esfriType>provider_esfri_type-landmark</tns:esfriType>" \
                "<tns:hostingLegalEntity>cyfronet</tns:hostingLegalEntity>" \
                "<tns:id>eosc.cyfronet</tns:id>" \
                "<tns:catalogueId>eosc</tns:catalogueId>" \
                "<tns:legalEntity>true</tns:legalEntity>" \
                "<tns:legalStatus>provider_legal_status-public_legal_entity</tns:legalStatus>" \
                "<tns:lifeCycleStatus>provider_life_cycle_status-operational</tns:lifeCycleStatus>" \
                "<tns:location>" \
                "<tns:city>Kraków</tns:city>" \
                "<tns:country>PL</tns:country>" \
                "<tns:postalCode>30-950</tns:postalCode>" \
                "<tns:region>Lesser Poland</tns:region>" \
                "<tns:streetNameAndNumber>ul. Nawojki 11</tns:streetNameAndNumber>" \
                "</tns:location>" \
                "<tns:logo>http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg</tns:logo>" \
                "<tns:mainContact>" \
                "<tns:email>john@doe.pl</tns:email>" \
                "<tns:firstName>John</tns:firstName>" \
                "<tns:lastName>Doe</tns:lastName>" +
              "</tns:mainContact>" \
                "<tns:merilScientificDomains>" \
                "<tns:merilScientificDomain>" \
                "<tns:merilScientificDomain>provider_meril_scientific_domain-other</tns:merilScientificDomain>" \
                "<tns:merilScientificSubdomain>provider_meril_scientific_subdomain-other-other</tns:merilScientificSubdomain>" \
                "</tns:merilScientificDomain>" +
              "</tns:merilScientificDomains>" \
                "<tns:multimedia/>" \
                "<tns:name>Test-Cyfronet #3</tns:name>" \
                "<tns:nationalRoadmaps>" \
                "<tns:nationalRoadmap>test</tns:nationalRoadmap>" \
                "<tns:nationalRoadmap>test2</tns:nationalRoadmap>" \
                "</tns:nationalRoadmaps>" +
              "<tns:networks>" \
                "<tns:network>provider_network-aegis</tns:network>" \
                "</tns:networks>" \
                "<tns:participatingCountries>" \
                "<tns:participatingCountry>BB</tns:participatingCountry>" \
                "<tns:participatingCountry>AT</tns:participatingCountry>" \
                "</tns:participatingCountries>" \
                "<tns:publicContacts>" \
                "<tns:publicContact><tns:email>g.porczyca@cyfronet.pl</tns:email></tns:publicContact>" \
                "</tns:publicContacts>" +
              "<tns:scientificDomains>" \
                "<tns:scientificDomain>" \
                "<tns:scientificDomain>scientific_domain-generic</tns:scientificDomain>" \
                "<tns:scientificSubdomain>scientific_subdomain-generic-generic</tns:scientificSubdomain>" \
                "</tns:scientificDomain>" +
              "</tns:scientificDomains>" \
                "<tns:societalGrandChallenges>" \
                "<tns:societalGrandChallenge>provider_societal_grand_challenge-secure_societies</tns:societalGrandChallenge>" \
                "</tns:societalGrandChallenges>" \
                "<tns:structureTypes>" \
                "<tns:structureType>provider_structure_type-mobile</tns:structureType>" \
                "</tns:structureTypes>" \
                "<tns:tags>" + "<tns:tag>tag</tns:tag>" +
              "<tns:tag>test</tns:tag>" \
                "<tns:tag>cyfro</tns:tag>" \
                "</tns:tags>" + "<tns:users>" +
              "<tns:user>" \
                "<tns:email>grck@qmail.com</tns:email>" \
                "<tns:id></tns:id>" + "<tns:name>Gaweł</tns:name>" +
              "<tns:surname>Porczyca</tns:surname>" \
                "</tns:user>" \
                "</tns:users>" +
              "<tns:website>http://www.cyfronet.pl</tns:website>" \
                "</tns:provider>" \
                "</tns:providerBundle>",
          "payloadFormat" => "xml"
        }
      )
    end
  end
  factory :jms_xml_rejected_provider, class: String do
    initialize_with do
      next(
        {
          "resourceId" => "a66bbf3b-ed20-4abd-905a-fd2cff575fe7",
          "resourceType" => "provider",
          "resource" =>
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
              "<tns:providerBundle xmlns:tns=\"http://einfracentral.eu\">" \
              "<tns:active>false</tns:active>" \
              "<tns:suspended>false</tns:suspended>" \
              "<tns:latestOnboardingInfo>" \
              "<tns:actionType>rejected</tns:actionType>" \
              "</tns:latestOnboardingInfo>" \
              "<tns:metadata>" \
              "<tns:modifiedAt>1613193818577</tns:modifiedAt>" \
              "<tns:modifiedBy>Gaweł Porczyca</tns:modifiedBy>" \
              "<tns:registeredAt>1601623322996</tns:registeredAt>" \
              "<tns:registeredBy>Gaweł Porczyca</tns:registeredBy>" \
              "<tns:terms>" \
              "<tns:term>grck@gmail.com</tns:term>" +
              "<tns:term>ar@test.com</tns:term>" \
                "</tns:terms>" \
                "</tns:metadata>" +
              "<tns:status>approved</tns:status>" \
                "<tns:provider>" \
                "<tns:ppid></tns:ppid>" \
                "<tns:abbreviation>CYFRONET</tns:abbreviation>" \
                "<tns:affiliations>" \
                "<tns:affiliation>asdf</tns:affiliation>" \
                "<tns:affiliation>test</tns:affiliation></tns:affiliations>" \
                "<tns:areasOfActivity>" \
                "<tns:areaOfActivity>provider_area_of_activity-applied_research</tns:areaOfActivity>" \
                "</tns:areasOfActivity>" +
              "<tns:certifications>" \
                "<tns:certification>ISO-345</tns:certification>" \
                "<tns:certification>ASE/EBU-2008</tns:certification>" \
                "</tns:certifications>" \
                "<tns:description>Test provider for jms queue</tns:description>" \
                "<tns:esfriDomains>" \
                "<tns:esfriDomain>provider_esfri_domain-energy</tns:esfriDomain>" \
                "</tns:esfriDomains>" \
                "<tns:esfriType>provider_esfri_type-landmark</tns:esfriType>" \
                "<tns:hostingLegalEntity>cyfronet</tns:hostingLegalEntity>" \
                "<tns:id>eosc.cyfronet</tns:id>" \
                "<tns:catalogueId>eosc</tns:catalogueId>" \
                "<tns:legalEntity>true</tns:legalEntity>" \
                "<tns:legalStatus>provider_legal_status-public_legal_entity</tns:legalStatus>" \
                "<tns:lifeCycleStatus>provider_life_cycle_status-operational</tns:lifeCycleStatus>" \
                "<tns:location>" \
                "<tns:city>Kraków</tns:city>" \
                "<tns:country>PL</tns:country>" \
                "<tns:postalCode>30-950</tns:postalCode>" \
                "<tns:region>Lesser Poland</tns:region>" \
                "<tns:streetNameAndNumber>ul. Nawojki 11</tns:streetNameAndNumber>" \
                "</tns:location>" \
                "<tns:logo>http://www.cyfronet.krakow.pl/_img/cyfronet_logo_kolor.jpg</tns:logo>" \
                "<tns:mainContact>" \
                "<tns:email>john@doe.pl</tns:email>" \
                "<tns:firstName>John</tns:firstName>" \
                "<tns:lastName>Doe</tns:lastName>" +
              "</tns:mainContact>" \
                "<tns:merilScientificDomains>" \
                "<tns:merilScientificDomain>" \
                "<tns:merilScientificDomain>provider_meril_scientific_domain-other</tns:merilScientificDomain>" \
                "<tns:merilScientificSubdomain>provider_meril_scientific_subdomain-other-other</tns:merilScientificSubdomain>" \
                "</tns:merilScientificDomain>" +
              "</tns:merilScientificDomains>" \
                "<tns:multimedia/>" \
                "<tns:name>Test-Cyfronet #3</tns:name>" \
                "<tns:nationalRoadmaps>" \
                "<tns:nationalRoadmap>test</tns:nationalRoadmap>" \
                "<tns:nationalRoadmap>test2</tns:nationalRoadmap>" \
                "</tns:nationalRoadmaps>" +
              "<tns:networks>" \
                "<tns:network>provider_network-aegis</tns:network>" \
                "</tns:networks>" \
                "<tns:participatingCountries>" \
                "<tns:participatingCountry>BB</tns:participatingCountry>" \
                "<tns:participatingCountry>AT</tns:participatingCountry>" \
                "</tns:participatingCountries>" \
                "<tns:publicContacts>" \
                "<tns:publicContact><tns:email>g.porczyca@cyfronet.pl</tns:email></tns:publicContact>" \
                "</tns:publicContacts>" +
              "<tns:scientificDomains>" \
                "<tns:scientificDomain>" \
                "<tns:scientificDomain>scientific_domain-generic</tns:scientificDomain>" \
                "<tns:scientificSubdomain>scientific_subdomain-generic-generic</tns:scientificSubdomain>" \
                "</tns:scientificDomain>" +
              "</tns:scientificDomains>" \
                "<tns:societalGrandChallenges>" \
                "<tns:societalGrandChallenge>provider_societal_grand_challenge-secure_societies</tns:societalGrandChallenge>" \
                "</tns:societalGrandChallenges>" \
                "<tns:structureTypes>" \
                "<tns:structureType>provider_structure_type-mobile</tns:structureType>" \
                "</tns:structureTypes>" \
                "<tns:tags>" + "<tns:tag>tag</tns:tag>" +
              "<tns:tag>test</tns:tag>" \
                "<tns:tag>cyfro</tns:tag>" \
                "</tns:tags>" + "<tns:users>" +
              "<tns:user>" \
                "<tns:email>grck@qmail.com</tns:email>" \
                "<tns:id></tns:id>" + "<tns:name>Gaweł</tns:name>" +
              "<tns:surname>Porczyca</tns:surname>" \
                "</tns:user>" \
                "</tns:users>" +
              "<tns:website>http://www.cyfronet.pl</tns:website>" \
                "</tns:provider>" \
                "</tns:providerBundle>",
          "payloadFormat" => "xml"
        }
      )
    end
  end
end
