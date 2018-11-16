# frozen_string_literal: true

class AffiliationMailer < ApplicationMailer
  def verification(affiliation)
    @affiliation = affiliation
    @user = affiliation.user

    mail(to: @affiliation.email, subject: "Affiliation confirmation required")
  end
end
