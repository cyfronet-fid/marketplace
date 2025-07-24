# frozen_string_literal: true

FactoryBot.define do
  factory :jms_json_service, class: String do
    skip_create
    transient do
      data do
        {
          resourceId: "13b90013-2e17-4ad9-a260-3b59a598f189",
          resourceType: "service",
          resource: {
            active: true,
            identifiers: ["eubi_eric.biomedical_imaging"],
            latest: true,
            metadata: {
              modifiedAt: 1_600_863_105_818,
              modifiedBy: "Marta Swiatkowska",
              registeredAt: 1_593_444_757_069,
              registeredBy: "Marta Swiatkowska"
            },
            service: {
              horizontalService: true,
              serviceCategories: ["service-category-compute"],
              changeLog: [],
              description:
                "&lt;p style=\"text-align: justify;\"&gt;A catalogue of corpora (datasets) made up of mainly " +
                  "Open Access scholarly publications.&lt;br /&gt; Users can view publicly available corpora " +
                  "that have been created with the OpenMinTeD Corpus Builder for Scholarly Works, or manually " +
                  "uploaded to the OpenMinTeD platform.&amp;nbsp;&lt;/p&gt; &lt;p style=\"text-align: justify;\"&gt;" +
                  "The catalogue can be browsed and searched via the faceted navigation facility or a google-like " +
                  "free text search query. All users can view the descriptions of the corpora (with administrative " +
                  "and technical information, such as language, domain, keywords, licence, resource creator, etc.), " +
                  "as well as the contents and, when available, the metadata descriptions of the individual files " +
                  "that compose them.&amp;nbsp;&lt;/p&gt; &lt;p style=\"text-align: justify;\"&gt; " +
                  "In addition, registered users can process them with the TDM applications offered by OpenMinTeD " +
                  "and download them in accordance with their licensing conditions.&lt;/p&gt;",
              helpdeskPage: "https://services.openminted.eu/support",
              id: "eosc.tp.openminted_catalogue_of_corpora_2",
              languageAvailabilities: ["english"],
              lastUpdate: "2018-09-05T00:00:00.000Z",
              lifeCycleStatus: "production",
              name: "OpenMinTeD Catalogue of Corpora 2",
              order: "http://support.d4science.org",
              geographicalAvailabilities: ["WW"],
              pricing: "http://openminted.eu/pricing/",
              paymentModel: "http://openminted.eu/pricing/",
              resourceOrganisation: "eosc.tp",
              resourceProviders: ["eosc.tp"],
              relatedSerources: [],
              requiredResources: [],
              serviceLevel: "http://openminted.eu/sla-agreement/",
              logo: "http://openminted.eu/wp-content/uploads/2018/08/catalogue-of-corpora.png",
              tagline: "Find easily accessible corpora of scholarly content and mine them!",
              tags: [
                "Text Mining",
                "Catalogue",
                "Research",
                "Data Mining",
                "TDM",
                "Corpora",
                "Datasets",
                "Scholarly literature",
                "Scientific publications",
                "Scholarly content"
              ],
              targetUsers: %w[researchers risk-assessors],
              termsOfUse: ["https://services.openminted.eu/support/termsAndConditions"],
              trainingInformation: "http://openminted.eu/support-training/",
              trl: "trl-7",
              webpage: "http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/",
              userManual: "http://openminted.eu/user-manual/",
              version: "1.0",
              statusMonitoring: nil,
              accessPolicy: nil
            },
            payloadFormat: "json"
          }
        }
      end
    end
    initialize_with { data.to_json }
  end
end
