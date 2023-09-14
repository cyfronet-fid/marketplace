# frozen_string_literal: true

class Services::BundlesController < ApplicationController
  def show
    @service = policy_scope(Service).friendly.find(params[:service_id])
    @bundle = policy_scope(@service.bundles.includes(:main_offer, :offers)).find_by(iid: params[:id])
    @bundle.store_analytics
    @offers = @bundle.all_offers
  end
end
