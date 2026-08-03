# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::DetailsComponent, type: :component do
  describe "resource predicates" do
    it "identifies deployable applications" do
      component = described_class.new(double(resource_type: "DeployableApplication"))

      expect(component).to be_deployable_application
    end

    it "does not identify deployable applications as services" do
      component = described_class.new(double(resource_type: "DeployableApplication"))

      expect(component).not_to be_service
    end

    it "identifies services case-insensitively by their resource type" do
      component = described_class.new(double(resource_type: "SERVICE"))

      expect(component).to be_service
    end

    it "does not identify services as deployable applications" do
      component = described_class.new(double(resource_type: "SERVICE"))

      expect(component).not_to be_deployable_application
    end

    it "does not identify an object without a resource type as a service" do
      component = described_class.new(Object.new)

      expect(component).not_to be_service
    end

    it "does not identify an object without a resource type as a deployable application" do
      component = described_class.new(Object.new)

      expect(component).not_to be_deployable_application
    end

    it "identifies catalogues by class" do
      expect(described_class.new(Catalogue.new)).to be_catalogue
    end

    it "identifies providers by class" do
      expect(described_class.new(Provider.new)).to be_provider
    end
  end

  describe "resource-specific metadata" do
    subject(:rendered_component) { render_inline(component) }

    let(:component) { described_class.new(object) }
    let(:object) do
      Service
        .new(resource_type: "Service")
        .tap do |service|
          service.define_singleton_method(:sqa) { [name: "SQA badge", url: "https://example.org/sqa"] }
          service.define_singleton_method(:keywords) { ["Data & AI", "FAIR"] }
          service.define_singleton_method(:learning_outcomes) { ["Understand FAIR principles"] }
          service.define_singleton_method(:configuration_templates) do
            [pid: "eosc.ct.fair.v1", url: "https://example.org/template"]
          end
          service.alternative_identifiers = [AlternativeIdentifier.new(identifier_type: "DOI", value: "10.1234/test")]
        end
    end

    it "renders the SQA card" do
      rendered_component

      expect(page).to have_css(".details-box.sqa", text: "SQA badge")
    end

    it "renders the keywords card" do
      rendered_component

      expect(page).to have_css(".details-box.keywords", text: "Data & AI")
    end

    it "renders the persistent identifiers card" do
      rendered_component

      expect(page).to have_css(".details-box.persistent_identifiers", text: "10.1234/test")
    end

    it "renders the learning outcomes card" do
      rendered_component

      expect(page).to have_css(".details-box.learning_outcomes", text: "Understand FAIR principles")
    end

    it "renders the configuration template card" do
      rendered_component

      expect(page).to have_css(".details-box.configuration_template", text: "eosc.ct.fair.v1")
    end

    it "links the SQA badge" do
      rendered_component

      expect(page).to have_link("SQA badge", href: "https://example.org/sqa")
    end

    it "links the configuration template" do
      rendered_component

      expect(page).to have_link("eosc.ct.fair.v1", href: "https://example.org/template")
    end

    context "with external search enabled" do
      before do
        allow(component).to receive(:external_search_enabled).and_return(true)
        allow(Mp::Application.config).to receive(:search_service_base_url).and_return("https://search.example.com")
      end

      it "URL-encodes keyword values for external search links" do
        rendered_component

        expect(page).to have_link(
          "Data & AI",
          href: "https://search.example.com/search/service?q=*&fq=tag_list:%22Data%20%26%20AI%22"
        )
      end
    end

    it "does not render provider-only multimedia resources for a service" do
      rendered_component

      expect(page).to have_no_css(".details-box.multimedia_resources")
    end
  end

  describe "description" do
    subject(:rendered_component) do
      render_inline(described_class.new(object, show_description: true))
    end

    let(:object) { Service.new(resource_type: "Service", description: "A **useful** service") }

    it "renders the description when requested by the public details view" do
      rendered_component

      expect(page).to have_css(".service-description-container.mb-5", text: "A useful service")
    end
  end

  describe "deployable application configuration template" do
    subject(:rendered_component) { render_inline(described_class.new(object)) }

    let(:object) do
      DeployableService.new(
        resource_type: "DeployableApplication",
        pid: "eosc.ct.application.v1",
        url: "https://example.org/template"
      )
    end

    it "renders the configuration template card when explicit metadata is absent" do
      rendered_component

      expect(page).to have_css(".details-box.configuration_template")
    end

    it "links the resource PID when explicit metadata is absent" do
      rendered_component

      expect(page).to have_link("eosc.ct.application.v1", href: "https://example.org/template")
    end
  end

  describe "tags" do
    subject(:rendered_component) { render_inline(component) }

    let(:component) { described_class.new(object) }
    let(:object) { Datasource.new(resource_type: "DataSource", tag_list: ["Data & AI", "FAIR"]) }

    it "renders the expected number of tags regardless of resource type" do
      rendered_component

      expect(page).to have_css(".details-box.tags .taglist-holder ul li", count: 2)
    end

    it "renders the first tag" do
      rendered_component

      expect(page).to have_link("Data & AI")
    end

    it "renders the second tag" do
      rendered_component

      expect(page).to have_link("FAIR")
    end

    context "with external search enabled" do
      before do
        allow(component).to receive(:external_search_enabled).and_return(true)
        allow(Mp::Application.config).to receive(:search_service_base_url).and_return("https://search.example.com")
      end

      it "URL-encodes tag values for external search links" do
        rendered_component

        expect(page).to have_link(
          "Data & AI",
          href: "https://search.example.com/search/service?q=*&fq=tag_list:%22Data%20%26%20AI%22"
        )
      end
    end
  end

  describe "multimedia resources" do
    subject(:rendered_component) { render_inline(described_class.new(object)) }

    let(:object) { Catalogue.new(link_multimedia_urls: multimedia_urls) }

    context "with a valid URL" do
      let(:multimedia_urls) { [Link::MultimediaUrl.new(name: "Video", url: "https://example.org/video")] }

      it "renders the resource as a link" do
        rendered_component

        expect(page).to have_link("Video", href: "https://example.org/video")
      end
    end

    context "with an invalid URL" do
      let(:multimedia_urls) { [Link::MultimediaUrl.new(name: "Video", url: "javascript:alert(1)")] }

      it "renders the label as text" do
        rendered_component

        expect(page).to have_text("Video")
      end

      it "does not render the label as a link" do
        rendered_component

        expect(page).to have_no_link("Video")
      end
    end

    context "with an invalid URL and no label" do
      let(:multimedia_urls) { [Link::MultimediaUrl.new(url: "ftp://example.org/video")] }

      it "renders the URL as text" do
        rendered_component

        expect(page).to have_text("ftp://example.org/video")
      end

      it "does not render the URL as a link" do
        rendered_component

        expect(page).to have_no_link("ftp://example.org/video")
      end
    end
  end
end
