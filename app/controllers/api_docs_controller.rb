# frozen_string_literal: true

class ApiDocsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def show
    @subsection = extract_subsection
    redirect_to api_docs_path, status: :bad_request if @subsection.nil?
  end

  def create
    regenerate_token
    respond_to do |format|
      notice = "Token regenerated successfully"
      format.html { redirect_to api_docs_path, notice: notice }
      format.turbo_stream { flash.now[:notice] = notice }
    end
  end

  private

  def extract_subsection
    subsection = params[:subsection]&.to_sym
    if subsection.blank?
      :introduction
    elsif helpers.api_wiki_subsections.include? subsection
      subsection
    end
  end

  def regenerate_token
    current_user.update!(authentication_token: nil)
  end
end
