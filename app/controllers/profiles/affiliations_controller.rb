# frozen_string_literal: true

class Profiles::AffiliationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_and_authorize, only: [:edit, :update, :destroy]

  def new
    @affiliation = Affiliation.new(user: current_user)
    authorize(@affiliation)
  end

  def create
    template = affiliation_template
    authorize(template)

    @affiliation = Affiliation::Create.new(template).call

    if @affiliation.persisted?
      redirect_to profile_path,
                  notice: "New affiliation created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if Affiliation::Update.new(@affiliation, permitted_attributes(@affiliation)).call
      redirect_to profile_path,
                  notice: "Affiliation updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @affiliation.destroy
    redirect_to profile_path,
                notice: "Affiliation destroyed"
  end

  private

    def affiliation_template
      Affiliation.new(permitted_attributes(Affiliation).
                      merge(user: current_user))
    end

    def find_and_authorize
      @affiliation = Affiliation.find_by(iid: params[:id])
      authorize(@affiliation)
    end
end
