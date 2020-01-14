# frozen_string_literal: true

class Admin::HelpItemsController < Admin::ApplicationController
  before_action :find_and_authorize, except: [:new, :create]

  def new
    @help_item = HelpItem.new(help_section: HelpSection.find_by(slug: params["section"]))
    authorize(@help_item)
  end

  def create
    @help_item = HelpItem.new(permitted_attributes(HelpItem))
    authorize(@help_item)

    if @help_item.save
      redirect_to admin_help_path(anchor: @help_item.help_section.slug),
                  notice: "New help item created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @help_item.update(permitted_attributes(HelpItem))
      redirect_to admin_help_path(anchor: @help_item.help_section.slug),
                  notice: "New help item created sucessfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @help_item.destroy!

    redirect_to admin_help_path(anchor: @help_item.help_section.slug),
                notice: "Help item destroyed"
  end

  private
    def find_and_authorize
      @help_item = HelpItem.find(params[:id])
      authorize(@help_item)
    end
end
