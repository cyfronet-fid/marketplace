# frozen_string_literal: true

module Presentable::LinksHelper
  def service_fields
    [links]
  end

  def provider_fields
    [provider_links]
  end

  def new_question_link(object = @object)
    object.instance_of?(Provider) ? new_provider_question_path(object) : new_service_question_path(object)
  end

  def new_question_prompt(object = @object)
    if Mp::Variant.pl?
      object.instance_of?(Provider) ? "Ask provider a question" : "Contact provider"
    else
      object.instance_of?(Provider) ? "Contact the organisation" : "Contact organisation"
    end
  end

  private

  # pl lists the profile links that only its Service::PlProfile carries.
  def links
    if Mp::Variant.pl?
      {
        name: "links",
        template: "links",
        fields: %w[
          webpage_url
          helpdesk_url
          helpdesk_email
          manual_url
          pricing_url
          training_information_url
          privacy_policy_url
          terms_of_use_url
          access_policies_url
          maintenance_url
        ],
        active_when_suspended: %w[
          webpage_url
          helpdesk_url
          helpdesk_email
          manual_url
          training_information_url
          privacy_policy_url
          terms_of_use_url
          access_policies_url
          maintenance_url
        ]
      }
    else
      {
        name: "links",
        template: "links",
        fields: %w[webpage_url privacy_policy_url terms_of_use_url access_policies_url],
        active_when_suspended: %w[webpage_url privacy_policy_url terms_of_use_url access_policies_url]
      }
    end
  end

  def provider_links
    { name: "links", template: "links", fields: %w[website] }
  end
end
