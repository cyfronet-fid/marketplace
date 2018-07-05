# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @affiliations = policy_scope(Affiliation).order(:iid).page(params[:page])
  end
end
