# frozen_string_literal: true

class AffiliationConfirmationsController < ApplicationController
  before_action :authenticate_user!

  def index
    confirmator = Affiliation::Confirm.new(current_user, params[:at])

    if confirmator.call
      redirect_to profile_affiliations_path,
                  notice: "Affiliation confirmed sucessfully"
    else
      redirect_to root_path,
                  alert: confirmator.error || "Unable to confirm your afiliation"
    end
  end
end
