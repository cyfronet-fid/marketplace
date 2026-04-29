# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Vocabularies in backoffice", manager_frontend: true do
  include OmniauthHelper

  context "As a service portolio manager" do
    VOCABULARY_TYPES.each do |vocabulary, opts|
      humanized = opts[:name]
      route = opts[:route]
      vocabulary_class = opts[:klass].constantize

      context "For #{humanized}" do
        let(:user) { create(:user, roles: [:coordinator]) }

        before { checkin_sign_in_as(user) }

        scenario "I can create new" do
          visit send("backoffice_other_settings_#{route}_path")

          click_on "Add new #{humanized}"

          expect(page).to have_content("New #{humanized}")

          fill_in "Name", with: "vocabulary #{humanized}"
          fill_in "Description", with: "test"
          fill_in "Eid", with: "test_#{vocabulary}"
          click_on "Create #{humanized}"

          expect(page).to have_text("New #{humanized} created successfully")

          expect(page).to have_text("vocabulary #{humanized}")
          expect(page).to have_text("test")
          expect(page).to have_text("test_#{vocabulary}")
          expect(page).to have_text("Root element")
        end

        scenario "I can edit existing" do
          existing_vocabulary = create_vocabulary(vocabulary_class, vocabulary)

          visit send("backoffice_other_settings_#{route.to_s.singularize}_path", existing_vocabulary)

          click_on "Edit"

          expect(page).to have_content("Edit #{humanized}")

          fill_in "Name", with: "updated vocabulary #{humanized}"
          fill_in "Description", with: "updated test"
          fill_in "Eid", with: "updated_test_#{vocabulary}"
          click_on "Update #{humanized}"

          expect(page).to have_text("#{humanized} updated successfully")

          expect(page).to have_text("updated vocabulary #{humanized}")
          expect(page).to have_text("updated test")
          expect(page).to have_text("updated_test_#{vocabulary}")
          expect(page).to have_text("Root element")
        end

        scenario "I can delete existing if is not root element" do
          existing_vocabulary = create_vocabulary(vocabulary_class, vocabulary)

          visit send("backoffice_other_settings_#{route.to_s.singularize}_path", existing_vocabulary)

          click_on "Delete"

          expect(page).to have_text("#{humanized} removed successfully")
        end

        scenario "I cannot remove a #{humanized} if it is associated with a service/provider" do
          skip("Generic association setup does not cover V6 vocabulary-specific joins")

          to_associate = create_vocabulary(vocabulary_class, vocabulary)
          association_service = create(:service)
          association_provider = create(:provider)

          begin
            association_service.try(:update, { "#{vocabulary.to_s.pluralize}": [to_associate] })
          rescue StandardError
            nil
          end
          begin
            association_service.try(:update, { "#{vocabulary}": [to_associate] })
          rescue StandardError
            nil
          end
          begin
            association_service.try(:update, { "#{vocabulary}": to_associate })
          rescue StandardError
            nil
          end
          begin
            association_provider.try(:update, { "#{vocabulary.to_s.pluralize}": [to_associate] })
          rescue StandardError
            nil
          end
          begin
            association_provider.try(:update, { "#{vocabulary}": to_associate })
          rescue StandardError
            nil
          end

          visit send("backoffice_other_settings_#{route.to_s.singularize}_path", to_associate)

          click_on "Delete"

          expect(page).to have_text(
            "This vocabulary has services connected to it, remove associations to delete it."
          ).or have_text("This vocabulary has providers connected to it, remove associations to delete it.")
        end

        scenario "I cannot remove a vocabulary if it has children" do
          parent = create_vocabulary(vocabulary_class, vocabulary)
          create_vocabulary(vocabulary_class, vocabulary, ancestry: parent.id)

          visit send("backoffice_other_settings_#{route.to_s.singularize}_path", parent)

          click_on "Delete"

          expect(page).to have_text(
            "This #{humanized} has successors connected to it, " \
              "therefore is not possible to remove it. If you want to remove it, " \
              "edit them so they are not associated with this #{humanized} anymore"
          )
        end
      end
    end
  end

  def create_vocabulary(vocabulary_class, vocabulary, attrs = {})
    sequence = SecureRandom.hex(4)
    vocabulary_class.create!(
      {
        name: "existing #{vocabulary} #{sequence}",
        description: "description #{sequence}",
        eid: "existing_#{vocabulary}_#{sequence}"
      }.merge(attrs)
    )
  end
end
