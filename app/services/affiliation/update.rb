# frozen_string_literal: true

class Affiliation::Update
  def initialize(affiliation, params)
    @affiliation = affiliation
    @params = params
  end

  def call
    @affiliation.assign_attributes(@params)
    email_changed = @affiliation.email_changed?

    @affiliation.save.tap do |saved|
      if saved && email_changed
        @affiliation.regenerate_token
        AffiliationMailer.verification(@affiliation).deliver_later
      end
    end
  end
end
