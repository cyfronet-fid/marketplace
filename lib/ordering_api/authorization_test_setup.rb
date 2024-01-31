# frozen_string_literal: true

module OrderingApi
  class AuthorizationTestSetup
    def call
      oms_admin1 =
        User.create!(uid: "oms2_admin", first_name: "oms2_admin", last_name: "oms2_admin", email: "email1@email.com")
      oms_admin2 =
        User.create!(uid: "oms3_admin", first_name: "oms3_admin", last_name: "oms3_admin", email: "email2@email.com")

      oms2 = OMS.create!(name: "OMS2", type: "global", administrators: [oms_admin1])
      oms3 = OMS.create!(name: "OMS3", type: "global", administrators: [oms_admin2])

      provider = Provider.create!(name: "provider")
      service1 =
        Service.create!(
          name: "s1",
          description: "asd",
          tagline: "asd",
          status: "published",
          providers: [provider],
          resource_organisation: provider,
          scientific_domains: [ScientificDomain.first],
          geographical_availabilities: ["PL"]
        )
      service2 =
        Service.create!(
          name: "s2",
          description: "asd",
          tagline: "asd",
          status: "published",
          providers: [provider],
          resource_organisation: provider,
          scientific_domains: [ScientificDomain.first],
          geographical_availabilities: ["PL"]
        )
      offer1 =
        Offer.create!(
          order_type: "open_access",
          name: "o1",
          description: "asd",
          service: service1,
          status: "published",
          primary_oms: oms2
        )
      offer2 =
        Offer.create!(
          order_type: "open_access",
          name: "o2",
          description: "asd",
          service: service2,
          status: "published",
          primary_oms: oms3
        )

      project_owner = User.create!(uid: "user", first_name: "user", last_name: "user", email: "email3@email.com")
      project1 =
        Project.create!(
          user: project_owner,
          name: "p1",
          email: "email4@email.com",
          country_of_origin: "PL",
          webpage: "https://www.cyfronet.krakow.pl/",
          organization: "asd",
          reason_for_access: "asd",
          customer_typology: "single_user",
          status: "active"
        )
      project2 =
        Project.create!(
          user: project_owner,
          name: "p2",
          email: "email4@email.com",
          country_of_origin: "PL",
          webpage: "https://www.cyfronet.krakow.pl/",
          organization: "asd",
          reason_for_access: "asd",
          customer_typology: "single_user",
          status: "active"
        )
      project3 =
        Project.create!(
          user: project_owner,
          name: "p3",
          email: "email4@email.com",
          country_of_origin: "PL",
          webpage: "https://www.cyfronet.krakow.pl/",
          organization: "asd",
          reason_for_access: "asd",
          customer_typology: "single_user",
          status: "active"
        )

      ProjectItem.create!(offer: offer1, project: project2, status: "ready", status_type: "ready")
      ProjectItem.create!(offer: offer1, project: project3, status: "ready", status_type: "ready")
      ProjectItem.create!(offer: offer2, project: project3, status: "ready", status_type: "ready")

      Message.create!(
        messageable: project1,
        author_role: "user",
        author: project_owner,
        scope: "public",
        message: "Public user message in project 1"
      )
      Message.create!(
        messageable: project1,
        author_role: "mediator",
        scope: "public",
        message: "Public mediator  message in project 1"
      )

      Message.create!(
        messageable: project3,
        author_role: "provider",
        scope: "public",
        message: "Public provider message in project3"
      )
      Message.create!(
        messageable: project3,
        author_role: "provider",
        scope: "user_direct",
        message: "User direct provider message in project3"
      )
    end
  end
end
