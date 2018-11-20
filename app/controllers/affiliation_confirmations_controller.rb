# frozen_string_literal: true

class AffiliationConfirmationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @affiliation = Affiliation.find_by_token(params[:at])
    @result = Affiliation::Confirm.new(current_user, @affiliation).call
    current_user.reload
  end
end
