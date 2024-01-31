# frozen_string_literal: true

FactoryBot.define do
  factory :jms_xml_service, class: String do
    skip_create
    initialize_with do
      next(
        {
          "resourceId" => "13b90013-2e17-4ad9-a260-3b59a598f189",
          "resourceType" => "service",
          "resource" =>
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
          <tns:serviceBundle xmlns:tns=\"http://einfracentral.eu\">
            <tns:active>true</tns:active>
            <tns:identifiers>
              <tns:originalId>eubi_eric.biomedical_imaging</tns:originalId>
            </tns:identifiers>
            <tns:latest>true</tns:latest>
            <tns:metadata>
              <tns:modifiedAt>1600863105818</tns:modifiedAt>
              <tns:modifiedBy>Marta Swiatkowska</tns:modifiedBy>
              <tns:registeredAt>1593444757069</tns:registeredAt>
              <tns:registeredBy>Marta Swiatkowska</tns:registeredBy>
            </tns:metadata>
            <tns:service>
              <tns:horizontalService>true</tns:horizontalService>
              <tns:serviceCategories>
                <tns:serviceCategory>service-category-compute</tns:serviceCategory>
              </tns:serviceCategories>
              <tns:categories>
              <tns:category>aggregator</tns:category>
              </tns:categories>
              <tns:changeLog></tns:changeLog>
              <tns:description>&lt;p style=\"text-align: justify;\"&gt;A catalogue of corpora (datasets) made up of mainly Open Access scholarly publications.&lt;br /&gt; Users can view publicly available corpora that have been created with the OpenMinTeD Corpus Builder for Scholarly Works, or manually uploaded to the OpenMinTeD platform.&amp;nbsp;&lt;/p&gt; &lt;p style=\"text-align: justify;\"&gt;The catalogue can be browsed and searched via the faceted navigation facility or a google-like free text search query. All users can view the descriptions of the corpora (with administrative and technical information, such as language, domain, keywords, licence, resource creator, etc.), as well as the contents and, when available, the metadata descriptions of the individual files that compose them.&amp;nbsp;&lt;/p&gt; &lt;p style=\"text-align: justify;\"&gt;In addition, registered users can process them with the TDM applications offered by OpenMinTeD and download them in accordance with their licensing conditions.&lt;/p&gt;</tns:description>
              <tns:helpdeskPage>https://services.openminted.eu/support</tns:helpdeskPage>
              <tns:id>eosc.tp.openminted_catalogue_of_corpora_2</tns:id>
              <tns:ppid></tns:ppid>
              <tns:languageAvailabilities>
                <tns:languageAvailability>english</tns:languageAvailability>
              </tns:languageAvailabilities>
              <tns:lastUpdate>2018-09-05T00:00:00.000Z</tns:lastUpdate>
              <tns:lifeCycleStatus>production</tns:lifeCycleStatus>
              <tns:name>OpenMinTeD Catalogue of Corpora 2aaaaaaaaaaassssssssssssaa</tns:name>
              <tns:order>http://support.d4science.org</tns:order>
              <tns:geographicalAvailabilities>
                <tns:geographicalAvailability>WW</tns:geographicalAvailability>
              </tns:geographicalAvailabilities>
              <tns:pricing>http://openminted.eu/pricing/</tns:pricing>
              <tns:paymentModel>http://openminted.eu/pricing/</tns:paymentModel>
              <tns:resourceOrganisation>eosc.tp</tns:resourceOrganisation>
              <tns:resourceProviders>
                <tns:resourceProviders>eosc.tp</tns:resourceProviders>
              </tns:resourceProviders>
              <tns:relatedSerources/>
              <tns:requiredResources/>
              <tns:serviceLevel>http://openminted.eu/sla-agreement/</tns:serviceLevel>
              <tns:subcategories>data</tns:subcategories>
              <tns:logo>http://openminted.eu/wp-content/uploads/2018/08/catalogue-of-corpora.png</tns:logo>
              <tns:tagline>Find easily accessible corpora of scholarly content and mine them!</tns:tagline>
              <tns:tags>
                <tns:tag>Text Mining</tns:tag>
                <tns:tag>Catalogue</tns:tag>
                <tns:tag>Research</tns:tag>
                <tns:tag>Data Mining</tns:tag>
                <tns:tag>TDM </tns:tag>
                <tns:tag>Corpora</tns:tag>
                <tns:tag>Datasets</tns:tag>
                <tns:tag>Scholarly literature</tns:tag>
                <tns:tag>Scientific publications</tns:tag>
                <tns:tag>Scholarly content</tns:tag>
              </tns:tags>
              <tns:targetUsers>
                <tns:targetUsers>researchers</tns:targetUsers>
                <tns:targetUsers>risk-assessors</tns:targetUsers>
              </tns:targetUsers>
              <tns:termsOfUse>
              <tns:termOfUse>https://services.openminted.eu/support/termsAndConditions</tns:termOfUse></tns:termsOfUse>
              <tns:trainingInformation>http://openminted.eu/support-training/</tns:trainingInformation>
              <tns:trl>trl-7</tns:trl>
              <tns:webpage>http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/</tns:webpage>
              <tns:userManual>http://openminted.eu/user-manual/</tns:userManual>
              <tns:version>1.0</tns:version>
              <tns:statusMonitoring/>
              <tns:accessPolicy/>
            </tns:service>
          </tns:serviceBundle>",
          "payloadFormat" => "xml"
        }
      )
    end
  end
end
