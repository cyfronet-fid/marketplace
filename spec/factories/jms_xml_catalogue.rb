# frozen_string_literal: true

FactoryBot.define do
  factory :jms_xml_catalogue, class: String do
    skip_create
    initialize_with do
      next(
        {
          "resourceId" => "ead951e7-06bf-40a6-aa9f-115d209c965c",
          "resourceType" => "catalogue",
          "resource" =>
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
              "<tns:catalogueBundle xmlns:tns=\"http://einfracentral.eu\">" \
              "<tns:active>true</tns:active>" \
              "<tns:suspended>false</tns:suspended>" \
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
                "<tns:catalogue>" \
                "<tns:abbreviation>test dev km</tns:abbreviation>" \
                "<tns:affiliations/>" \
                "<tns:description>description well written</tns:description>" \
                "<tns:id>test_dev_km</tns:id>" \
                "<tns:legalEntity>true</tns:legalEntity>" \
                "<tns:location>" \
                " <tns:city>Krakow</tns:city>" \
                "<tns:country>PL</tns:country>" \
                "<tns:postalCode>30-950</tns:postalCode>" \
                "<tns:streetNameAndNumber>Nawojki 11</tns:streetNameAndNumber>" \
                "</tns:location>" \
                "<tns:logo>https://www.cyfronet.pl/zalacznik/8437</tns:logo>" \
                "<tns:mainContact>" \
                " <tns:email>ymmarsza@cyf-kr.edu.pl</tns:email>" \
                "<tns:firstName>Krzysztof</tns:firstName>" \
                "<tns:lastName>Marszalek</tns:lastName>" \
                "<tns:phone></tns:phone>" \
                "</tns:mainContact>" \
                "<tns:multimedia/>" \
                "<tns:name>test dev km</tns:name>" \
                "<tns:networks/>" \
                "<tns:participatingCountries>" \
                " <tns:participatingCountry>PL</tns:participatingCountry>" \
                "</tns:participatingCountries>" \
                "<tns:publicContacts>" \
                "<tns:publicContact>" \
                " <tns:email>ymmarsza@cyf-kr.edu.pl</tns:email>" \
                "<tns:phone></tns:phone>" \
                "</tns:publicContact>" \
                "</tns:publicContacts>" \
                "<tns:scientificDomains/>" \
                "<tns:tags/>" \
                "<tns:users>" \
                " <tns:user>" \
                "  <tns:email>ymmarsza@cyf-kr.edu.pl</tns:email>" \
                " <tns:id></tns:id>" \
                "<tns:name>Krzysztof</tns:name>" \
                "<tns:surname>Marszalek</tns:surname>" \
                "</tns:user>" \
                "</tns:users>" \
                "<tns:website>http://website.org</tns:website>" \
                "</tns:catalogue>" \
                "</tns:catalogueBundle>",
          "payloadFormat" => "xml"
        }
      )
    end
  end
end
