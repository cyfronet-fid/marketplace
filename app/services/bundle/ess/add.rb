# frozen_string_literal: true

class Bundle::Ess::Add < ApplicationService
  def initialize(bundle, async: true, dry_run: false)
    super()
    @bundle = bundle
    @type = "bundle"
    @async = async
    @dry_run = dry_run
  end

  def call
    if @dry_run
      ess_data
    else
      @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
    end
  end

  private

  def payload
    { action: "update", data_type: @type, data: ess_data }.as_json
  end

  def ess_data
    {
      id: @bundle.id,
      name: @bundle.name,
      bundle_goals: @bundle.bundle_goals.map(&:name),
      capabilities_of_goals: @bundle.capabilities_of_goals.map(&:name),
      main_offer_id: @bundle.main_offer.id,
      description: @bundle.description,
      target_users: @bundle.target_users.map(&:name),
      scientific_domains: @bundle.scientific_domains&.map { |sd| hierarchical_to_s(sd) },
      research_steps: @bundle.research_steps.map(&:name),
      offer_ids: @bundle.offers.map(&:id),
      related_training: @bundle.related_training,
      contact_email: @bundle.contact_email,
      helpdesk_url: @bundle.helpdesk_url,
      service_id: @bundle.service.id,
      resource_organisation: @bundle.resource_organisation.name,
      providers:
        (
          [@bundle.main_offer.service.providers.map(&:name)] +
            @bundle.offers.map { |o| o.service.providers.map(&:name) }
        ).flatten.uniq
    }
  end
end
