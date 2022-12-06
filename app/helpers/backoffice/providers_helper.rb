# frozen_string_literal: true

module Backoffice::ProvidersHelper
  def cant_edit(attribute)
    !policy([:backoffice, @provider]).permitted_attributes.include?(attribute)
  end

  def hosting_legal_entity_input(form)
    form.input :hosting_legal_entity,
               collection: Vocabulary.where(type: "Vocabulary::HostingLegalEntity"),
               disabled: cant_edit(:hosting_legal_entity),
               label_method: :name,
               value_method: :id,
               input_html: {
                 multiple: false,
                 data: {
                   choice: true
                 }
               }
  end
end
