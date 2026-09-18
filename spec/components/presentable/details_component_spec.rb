# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::DetailsComponent, type: :component do
  describe "resource predicates" do
    it "identifies deployable applications by their resource type" do
      component = described_class.new(double(resource_type: "DeployableApplication"))

      expect(component).to be_deployable_application
      expect(component).not_to be_service
    end

    it "identifies services case-insensitively by their resource type" do
      component = described_class.new(double(resource_type: "SERVICE"))

      expect(component).to be_service
      expect(component).not_to be_deployable_application
    end

    it "handles objects without a resource type" do
      component = described_class.new(Object.new)

      expect(component).not_to be_service
      expect(component).not_to be_deployable_application
    end

    it "identifies catalogues and providers by class" do
      expect(described_class.new(Catalogue.new)).to be_catalogue
      expect(described_class.new(Provider.new)).to be_provider
    end
  end

  describe "resource-specific metadata" do
    subject(:rendered_component) { render_inline(described_class.new(object)) }

    let(:object) do
      Service
        .new(resource_type: "Service")
        .tap do |service|
          service.define_singleton_method(:sqa) { [{ name: "SQA badge", url: "https://example.org/sqa" }] }
          service.define_singleton_method(:keywords) { %w[Cloud FAIR] }
          service.define_singleton_method(:learning_outcomes) { ["Understand FAIR principles"] }
          service.define_singleton_method(:configuration_templates) do
            [{ pid: "eosc.ct.fair.v1", url: "https://example.org/template" }]
          end
          service.alternative_identifiers = [AlternativeIdentifier.new(identifier_type: "DOI", value: "10.1234/test")]
        end
    end

    it "renders cards for metadata present on the resource" do
      rendered_component

      expect(page).to have_css(".details-box.sqa", text: "SQA badge")
      expect(page).to have_css(".details-box.keywords", text: "Cloud")
      expect(page).to have_css(".details-box.persistent_identifiers", text: "10.1234/test")
      expect(page).to have_css(".details-box.learning_outcomes", text: "Understand FAIR principles")
      expect(page).to have_css(".details-box.configuration_template", text: "eosc.ct.fair.v1")
      expect(page).to have_link("SQA badge", href: "https://example.org/sqa")
      expect(page).to have_link("eosc.ct.fair.v1", href: "https://example.org/template")
    end

    it "does not render provider-only multimedia resources for a service" do
      rendered_component

      expect(page).to have_no_css(".details-box.multimedia_resources")
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

    it "uses the resource PID and URL when explicit template metadata is absent" do
      rendered_component

      expect(page).to have_css(".details-box.configuration_template")
      expect(page).to have_link("eosc.ct.application.v1", href: "https://example.org/template")
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

      it "renders the label as plain text" do
        rendered_component

        expect(page).to have_text("Video")
        expect(page).to have_no_link("Video")
      end
    end

    context "with an invalid URL and no label" do
      let(:multimedia_urls) { [Link::MultimediaUrl.new(url: "ftp://example.org/video")] }

      it "renders the URL as plain text" do
        rendered_component

        expect(page).to have_text("ftp://example.org/video")
        expect(page).to have_no_link("ftp://example.org/video")
      end
    end
  end
end
