# frozen_string_literal: true

class Admin::HelpSectionsController < Admin::ApplicationController
  before_action :find_and_authorize, except: %i[new create]

  def new
    @help_section = HelpSection.new
    authorize(@help_section)
  end

  def create
    @help_section = HelpSection.new(permitted_attributes(HelpSection))
    authorize(@help_section)

    if @help_section.save
      redirect_to admin_help_path, notice: "New help category created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @help_section.update(permitted_attributes(HelpSection))
      redirect_to admin_help_path, notice: "Help category updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @help_section.destroy!

    redirect_to admin_help_path, notice: "Help category removed successfully"
  end

  private

  def find_and_authorize
    @help_section = HelpSection.friendly.find(params[:id])
    authorize(@help_section)
  end
end
