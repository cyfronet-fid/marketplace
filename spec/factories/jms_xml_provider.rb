# frozen_string_literal: true


FactoryBot.define do
  factory :jms_xml_provider, class: String do
    skip_create
    initialize_with do
      next {
        "resourceId" => "13b90013-2e17-4ad9-a260-3b59a598f189",
        "resourceType" => "provider",
        "resource" => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                      "<tns:provider xmlns:tns=\"http://einfracentral.eu\">" +
                        "<tns:active>true</tns:active>" +
                        "<tns:additionalInfo>no</tns:additionalInfo>" +
                        "<tns:catalogueOfResources>http://no.i.dont</tns:catalogueOfResources>" +
                        "<tns:contactInformation>test phone number" +
                          "</tns:contactInformation>" +
                          "<tns:id>tp</tns:id>" +
                          "<tns:logo>https://cdn.shopify.com/s/files/1/0553/3925/products/logo_developers_grande.png?v=1432756867</tns:logo>" +
                          "<tns:name>Test Provider 2</tns:name>" +
                          "<tns:publicDescOfResources>http://no.i.dont</tns:publicDescOfResources>" +
                          "<tns:status>approved</tns:status>" +
                        "<tns:users>" +
                          "<tns:user>" +
                            "<tns:email>spyroukon@gmail.com</tns:email>" +
                            "<tns:id>116412069335017445275@google.com</tns:id>" +
                            "<tns:name>Κωνσταντίνος</tns:name>" +
                            "<tns:surname>Σπύρου</tns:surname>" +
                          "</tns:user>" +
                          "<tns:user>" +
                            "<tns:email>martaswiatkowska8@gmail.com</tns:email>" +
                            "<tns:name>Marta</tns:name>" +
                            "<tns:surname>Swiatkowska</tns:surname>" +
                          "</tns:user>" +
                        "</tns:users>" +
                        "<tns:website>http://beta.providers.eosc-portal.eu</tns:website>" +
                      "</tns:provider>",
        "payloadFormat" => "xml"
      }
    end
  end
end
