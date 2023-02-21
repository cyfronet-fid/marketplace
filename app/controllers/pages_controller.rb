# frozen_string_literal: true

class PagesController < ApplicationController
  def about; end

  def about_projects; end

  def communities
    @platforms = Platform.all.order(:name)
  end

  def target_users
    @target_users = TargetUser.all.order(:name).partition { |tu| tu.name != "Other" }.flatten(1)
  end

  def landing_page
    @discover_communities = [
      {
        title: "ENVRI Fair – the way to understanding of the Earth System",
        body:
          "ENVRI is a community of environmental research infrastructures
        working together to observe the Earth as one system. Community
        collaborates to provide environmental data, tools, and other
        services that are Open and FAIR, and can be easily used by anyone
        for free.",
        path: "https://envri.eu/",
        image: "landing_page/carousel/envri.svg"
      },
      {
        title: "ESCAPE – the consistent European research infrastructure ecosystem",
        body:
          "The cluster provides common innovative solutions for the
        management, curation, and deposition of data, for the data driven
        science economy, that span over a series of large domains in
        fundamental research: astronomy, astrophysics, astroparticle
        physics, high energy physics, particle and nuclear physics.",
        path: "https://projectescape.eu/",
        image: "landing_page/carousel/logo-Escape_2.svg"
      },
      {
        title: "EOSC-Life open digital space for life sciences",
        body:
          "The data, digital services and advanced facilities vital for life
        science research must be findable, accessible, interoperable,
        reusable (FAIR) across scientific disciplines and national
        boundaries. Together they cover all aspects of life science
        research and all life science domains.",
        path: "https://www.eosc-life.eu/",
        image: "landing_page/carousel/eosc-life.svg"
      },
      {
        title: "PaNOSC - adopting FAIR data practices at photon and neutron sources",
        body:
          "The mission of the community is to contribute to the realization
        of a data commons for Neutron and Photon science, providing
        services and tools for data storage, analysis and simulation, for
        the many scientists from existing and future disciplines using
        data from photon and neutron sources.",
        path: "https://www.panosc.eu/",
        image: "landing_page/carousel/panosc.svg"
      },
      {
        title: "SSHOC – towards the complete SSH ecosystem",
        body:
          "Social Sciences & Humanities Open Cloud is a project that unites
        20 partner organizations and their 27 associates in developing the
        social sciences and humanities area of the European Open Science
        Cloud.",
        path: "https://www.sshopencloud.eu/",
        image: "landing_page/carousel/sshoc-stakeholders.svg"
      }
    ]
    render layout: "clear"
  end
end
