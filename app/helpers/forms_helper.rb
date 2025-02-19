# frozen_string_literal: true

module FormsHelper
  def link_to_add_array_field(model, field_name)
    content_tag(
      :a,
      "Add new " + t("simple_form.add_new_array_item.#{model}.#{field_name}"),
      class: "btn btn-sm btn-primary disablable",
      data: {
        action: "click->form#addNewArrayField",
        wrapper: "#{model}_#{field_name}",
        name: "#{model}[#{field_name}][]",
        class: "form-control text optional"
      }
    )
  end

  def snake_cased(model_name)
    model_name.parameterize(separator: "_")
  end

  def checkbox_class(option, values)
    enabled = values.include?(option[:id].to_s)
    state = enabled ? "checked" : "unchecked"
    if values && option[:children]
      if (option[:children]&.map { |c| c[:id].to_s } & values).size.between?(1, option[:children].size - 1)
        "indeterminate"
      else
        state
      end
    end
  end

  def contact_form_message
    message =
      "  Accept EOSC Helpdesk <a target=\"_blank\" href=\"https://eosc-helpdesk.scc.kit.edu/privacy-policy\">" +
        "Data Privacy Policy</a> & <a target=\"_blank\" " +
        "href=\"https://eosc-helpdesk.scc.kit.edu/aup\">Acceptable Use Policy</a>"
    message.html_safe
  end

  def other_offers(service)
    offer_ids = service.offers.map(&:id)
    Offer
      .includes(:service)
      .accessible
      .reject { |item| item.id.in? offer_ids }
      .map { |item| ["#{item.service.name} > #{item.name}", item.id] }
  end

  def render_data_administrator(form, object)
    render "backoffice/providers/data_administrator_fields", data_administrator_form: form, provider: object
  end

  def render_link(form, object, link_name)
    render "backoffice/common_parts/form/link_fields", link_form: form, object: object, link_name: link_name
  end

  def render_persistent_identity_system(form, object)
    render "backoffice/common_parts/form/persistent_identity_system_fields",
           link_form: form,
           object: object,
           name: "persistentIdentitySystem"
  end

  def render_public_contact(public_contact_form, object)
    render "backoffice/common_parts/form/public_contact_fields",
           public_contact_form: public_contact_form,
           object: object,
           provider_form: object.is_a?(Provider)
  end

  def action_prompt(object, action)
    entities = object == "catalogue" ? "providers, services, offers and bundles" : "services, offers and bundles"
    warning = "CAUTION!\nThis action cannot be undone." if action == "remove"
    published = "published " if action != "remove"
    message =
      "Are you sure you want to %{action} this %{object}? It will %{action} " +
        "all dependent %{published}%{entities}.\n\n%{warning}"
    _(message % { action: _(action), entities: entities, object: object, published: published, warning: warning })
  end

  def dial_codes
    Country.all.map { |c| ["#{c.iso_short_name} #{c.emoji_flag} (+#{c.country_code})", "value" => c.country_code] }
  end
end
