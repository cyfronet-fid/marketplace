# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller, backend: true do
  controller do
    attr_accessor :params
    include Service::Recommendable
  end

  let!(:params) { ActionController::Parameters.new }
  let!(:active_filters) { [] }

  before(:each) { controller.params = params }

  transformer = Service::Recommendable::FILTER_PARAM_TRANSFORMERS

  it "Should return proper IDs for single roots" do
    scientific_domain = create(:scientific_domain)
    category = create(:category, name: "root")
    provider = create(:provider)
    target_user = create(:target_user)

    expect(transformer.length).to eq(6)
    expect(transformer[:scientific_domains].call(scientific_domain.id)).to match_array([scientific_domain.id])
    expect(transformer[:category_id].call(category.slug)).to match_array([category.id])
    expect(transformer[:providers].call(provider.id)).to match_array([provider.id])
    expect(transformer[:target_users].call(target_user.id)).to match_array([target_user.id])
  end

  it "Should return proper IDs for multiple roots" do
    scientific_domains = create_list(:scientific_domain, 10)
    scientific_domains_id = scientific_domains.map(&:id)

    categories = create_list(:category, 10)
    categories_slug = []
    categories_id = []
    categories.each do |cat|
      categories_slug << cat.slug
      categories_id << cat.id
    end

    providers = create_list(:provider, 10)
    providers_id = providers.map(&:id)

    target_users = create_list(:target_user, 10)
    target_users_id = target_users.map(&:id)

    expect(transformer[:scientific_domains].call(scientific_domains_id)).to match_array(scientific_domains_id)

    # It is impossible to choose multiple root categories - only one ID of the first slug should be returned
    expect(transformer[:category_id].call(categories_slug)).to match_array(categories_id[0])
    expect(transformer[:providers].call(providers_id)).to match_array(providers_id)
    expect(transformer[:target_users].call(target_users_id)).to match_array(target_users_id)
  end

  it "Should return proper IDs for a tree of scientific domains and categories" do
    sd_parent = create(:scientific_domain, name: "parent")
    sd_child = create(:scientific_domain, name: "child", parent: sd_parent)
    cat_parent = create(:category, name: "parent")
    cat_child = create(:category, name: "child", parent: cat_parent)

    expect(transformer[:scientific_domains].call(sd_parent.id)).to match_array([sd_parent.id, sd_child.id])
    expect(transformer[:scientific_domains].call(sd_child.id)).to match_array([sd_child.id])
    expect(transformer[:scientific_domains].call([sd_parent.id, sd_child.id])).to match_array(
      [sd_parent.id, sd_child.id]
    )

    expect(transformer[:category_id].call(cat_parent.slug)).to match_array([cat_parent.id, cat_child.id])
    expect(transformer[:category_id].call(cat_child.slug)).to match_array([cat_child.id])
    expect(transformer[:category_id].call([cat_parent.slug, cat_child.slug])).to match_array(
      [cat_parent.id, cat_child.id]
    )
  end

  it "Should return proper IDs for categories that name includes spaces" do
    transformer = transformer[:category_id]
    category = create(:category, name: "name which includes spaces")
    expect(transformer.call(category.slug)).to match_array([category.id])
  end

  it "Should use simple recommender_lib on unknown recommender_lib host" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    expect(Recommender::SimpleRecommender).to receive(:new).and_call_original

    controller.fetch_recommended
  end

  xit "Should fetch recommended service ids" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return("localhost:5000"))

    services_ids = [1, 2, 3, 4, 5]
    allow(Faraday).to receive(:post).and_return(double(status: 200, body: { "recommendations" => services_ids }))
    expect(Faraday).to receive(:post) do |_, _, body|
      body = JSON.parse(body)
      expect(body["timestamp"]).not_to be_nil
      expect(body["unique_id"].to_i).not_to be_nil
      expect(body["visit_id"].to_i).not_to be_nil
      expect(body["page_id"]).to eq "/service"
      expect(body["panel_id"]).to eq "v1"
      expect(body["engine_version"]).to eq "RL"
      expect(body["search_phrase"]).to be nil
      expect(body["logged_user"]).to be false
      expect(body["filters"]).to be nil
    end
    expect(Service).to receive(:where).and_return([])
    expect(Recommender::SimpleRecommender).not_to receive(:new)

    controller.fetch_recommended
  end
end
