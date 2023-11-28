# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller, backend: true do
  controller do
    attr_accessor :params
    include Service::Searchable
  end

  let!(:providers) { create_list(:provider, 2) }
  let!(:categories) { create_list(:category, 2) }

  let!(:service1) do
    create(
      :service,
      name: "duper super name",
      resource_organisation: providers.first,
      providers: providers,
      categories: [categories.first],
      tag_list: "tag1, tag2"
    )
  end
  let!(:service2) do
    create(
      :service,
      name: "very different title",
      resource_organisation: providers.first,
      providers: [providers.first],
      categories: categories,
      tag_list: "tag2"
    )
  end
  let!(:offer1) { create(:offer, service: service1, name: "Offer 1") }
  let!(:offer2) { create(:offer, service: service1, name: "Offer 2") }
  let!(:offer3) { create(:offer, service: service1, name: "Offer 3") }

  let!(:params) { ActionController::Parameters.new }
  let!(:provider_filter) { Filter::Provider.new(params: params) }
  let!(:tag_filter) { Filter::Tag.new(params: params) }
  let!(:filters) { [provider_filter, tag_filter] }

  before(:each) { controller.params = params }

  context "#search " do
    before(:each) { Offer.reindex }

    context "without filters set" do
      let!(:params) { ActionController::Parameters.new }
      it "returns correct service list" do
        results = controller.search(Service.all, filters)
        offers = results.second
        services = results.first.results

        expect(services.size).to eq(2)
        expect(services).to contain_exactly(service1, service2)

        expect(offers.size).to eq(1)
        expect(offers[service1.id].size).to eq(3)
      end
    end

    context "with providers and resource organisation filters set" do
      let!(:params) { ActionController::Parameters.new("providers" => providers.second.id) }
      it "returns correct service list" do
        results = controller.search(Service.all, filters)
        offers = results.second
        services = results.first.results

        expect(services.size).to eq(1)
        expect(services).to include(service1)
        expect(services).not_to include(service2)

        expect(offers.size).to eq(1)
        expect(offers[service1.id].size).to eq(3)
      end
    end

    context "with filters and category set" do
      let!(:params) do
        ActionController::Parameters.new("providers" => providers.second.id, "category_id" => categories.second.id)
      end
      it "returns empty service list when category contradicts provider filter" do
        results = controller.search(Service.all, filters)
        offers = results.second
        services = results.first.results

        expect(services.size).to eq(0)
        expect(offers.size).to eq(0)
      end
    end

    context "with filters and category set" do
      let!(:params) do
        ActionController::Parameters.new("providers" => providers.first.id, "category_id" => categories.second.id)
      end
      it "returns correct service list" do
        results = controller.search(Service.all, filters).first.results
        expect(results.size).to eq(1)
        expect(results).to include(service2)
        expect(results).not_to include(service1)
      end
    end

    context "with query" do
      let!(:params) { ActionController::Parameters.new("q" => "duper super") }
      it "returns correct service list" do
        results = controller.search(Service.all, filters).first.results
        expect(results.size).to eq(1)
        expect(results).to include(service1)
        expect(results).not_to include(service2)
      end
    end
  end

  context "#filter_counters" do
    context "provider set" do
      let!(:params) { ActionController::Parameters.new("providers" => providers.first.id) }
      it "returns counters for providers when tag filter not set" do
        expect(controller.filter_counters(Service.all, filters, provider_filter)).to eq(
          providers.first.id => 2,
          providers.second.id => 1
        )
      end
    end

    context "tag set" do
      let!(:params) { ActionController::Parameters.new("tag" => "tag1") }
      it "returns counters for providers when tag filter set and limits results" do
        expect(controller.filter_counters(Service.all, filters, provider_filter)).to eq(
          providers.first.id => 1,
          providers.second.id => 1
        )
      end
    end

    context "provider and resource organisation set" do
      let!(:params) { ActionController::Parameters.new("providers" => providers.first.id) }
      it "returns counters for tags when provider filter set but does not limit results" do
        expect(controller.filter_counters(Service.all, filters, tag_filter)).to eq("tag1" => 1, "tag2" => 2)
      end
    end

    context "provider and resource organisation set" do
      let!(:params) { ActionController::Parameters.new("providers" => providers.second.id) }
      it "returns counters for tags when provider filter set and limits results" do
        expect(controller.filter_counters(Service.all, filters, tag_filter)).to eq("tag1" => 1, "tag2" => 1)
      end
    end
  end

  context "#category_counters" do
    context "category_id set" do
      let!(:params) { ActionController::Parameters.new("category_id" => categories.first.id) }
      it "checks if set category_id doesn't affect counters" do
        counters = controller.category_counters(Service.all, filters)
        expect(counters.class).to eq Hash
        expect(counters).to eq(categories.first.id => 2, categories.second.id => 1, nil => 2)
      end
    end

    context "#category_counters and #filter counters interrelationship" do
      let!(:params) { ActionController::Parameters.new("providers" => providers.second.id) }
      it "checks category counters validity" do
        counters = controller.category_counters(Service.all, filters)
        expect(counters.class).to eq Hash
        expect(counters).to eq(categories.first.id => 1, nil => 1)
      end
    end

    context "with query" do
      let!(:params) { ActionController::Parameters.new("q" => "duper super") }
      it "checks if correct counters are returned" do
        counters = controller.category_counters(Service.all, filters)
        expect(counters.class).to eq Hash
        expect(counters).to eq(categories.first.id => 1, nil => 1)
      end
    end

    context "with query and filter" do
      let!(:params) { ActionController::Parameters.new("q" => "very different", "providers" => providers.second.id) }
      it "checks if query, filters, and categories counters work together" do
        counters = controller.category_counters(Service.all, filters)
        expect(counters.class).to eq Hash
        expect(counters).to eq(nil => 0)
      end
    end
  end

  context "filter type tests" do
    let!(:collection) { create_list(:provider, 3) }
    let!(:field_name) { :providers }
    let!(:param_name) { :providers }
    let!(:filter_class) { Filter::Provider }

    let!(:service1) { create(:service, field_name => [collection.first]) }
    let!(:service2) { create(:service, field_name => [collection.second]) }
    let!(:service4) { create(:service, field_name => [collection.third]) }

    let!(:value_method) { :id }
    let!(:values) { [collection.first.send(value_method), collection.second.send(value_method)] }
    let!(:params) { ActionController::Parameters.new(param_name => values) }
    let!(:filters) { [filter_class.new(params: params)] }

    def basic_test
      results = controller.search(Service.all, filters).first.results
      expect(results.size).to eq(2)
      expect(results).to include(service1)
      expect(results).to include(service2)
    end

    context Filter::Provider do
      it "checks if provider and resource organisation filter works" do
        basic_test
      end
    end

    context Filter::Tag do
      let!(:collection) { %w[tag1 tag2 tag3] }
      let!(:field_name) { :tag_list }
      let!(:param_name) { :tag }
      let!(:filter_class) { Filter::Tag }
      let!(:value_method) { :itself }
      it "checks if tag filter works" do
        basic_test
      end
    end

    context Filter::Platform do
      let!(:collection) { create_list(:platform, 3) }
      let!(:field_name) { :platforms }
      let!(:param_name) { :related_platforms }
      let!(:filter_class) { Filter::Platform }
      it "checks if platform filter works" do
        basic_test
      end
    end

    context Filter::ScientificDomain do
      let!(:collection) { create_list(:scientific_domain, 3) }
      let!(:field_name) { :scientific_domains }
      let!(:param_name) { :scientific_domains }
      let!(:filter_class) { Filter::ScientificDomain }
      it "checks if scientific domain filter works" do
        basic_test
      end
    end

    context Filter::TargetUser do
      let!(:collection) { create_list(:target_user, 3) }
      let!(:field_name) { :target_users }
      let!(:param_name) { :dedicated_for }
      let!(:index) { :dedicated_for }
      let!(:filter_class) { Filter::TargetUser }
      it "checks if target group filter works" do
        basic_test
      end
    end

    context Filter::Rating do
      let!(:collection) { [5.0, 4.0, 1.0] }
      let!(:service1) do
        create(:service).tap do |s|
          s.rating = collection.first
          s.save
        end
      end
      let!(:service2) do
        create(:service).tap do |s|
          s.rating = collection.second
          s.save
        end
      end
      let!(:service4) do
        create(:service).tap do |s|
          s.rating = collection.third
          s.save
        end
      end
      let!(:field_name) { :rating }
      let!(:param_name) { :rating }
      let!(:values) { 2.0 }
      let!(:filter_class) { Filter::Rating }
      it "checks if rating filter works" do
        Service.reindex
        basic_test
      end
    end

    context Filter::UpstreamSource do
      let!(:service1) { create(:service) }
      let!(:service2) { create(:service) }
      let!(:service4) { create(:service) }
      let!(:service_source1) { create(:service_source, source_type: "eosc_registry", service_id: service1.id) }
      let!(:service_source2) { create(:service_source, source_type: "eosc_registry", service_id: service2.id) }
      let!(:filter_class) { Filter::UpstreamSource }
      let!(:values) { "eosc_registry" }
      let!(:param_name) { :source }
      let!(:field_name) { :source }
      it "checks if upstream source filter works" do
        service1.upstream = service_source1
        service2.upstream = service_source2
        service1.save!
        service2.save!
        Service.reindex
        basic_test
      end
    end

    context Filter::Location do
      let!(:collection) { %w[PL BR EO] }
      let!(:service1) do
        create(
          :service,
          geographical_availabilities: Array.wrap([Country.load(collection.first), Country.load(collection.third)])
        )
      end
      let!(:service2) do
        create(
          :service,
          geographical_availabilities: Array.wrap([Country.load(collection.second), Country.load(collection.third)])
        )
      end
      let!(:service4) { create(:service, geographical_availabilities: Array.wrap(Country.load(collection.second))) }
      let!(:field_name) { :geographical_availabilities }
      let!(:param_name) { :geographical_availabilities }
      let!(:filter_class) { Filter::Location }

      context "with filter country value" do
        let!(:values) { "Poland" }
        it "checks if location filter works" do
          Service.reindex
          basic_test
        end
      end

      context "with filter region value" do
        let!(:values) { "Europe" }
        it "checks if location filter works" do
          Service.reindex
          basic_test
        end
      end
    end
  end
end
