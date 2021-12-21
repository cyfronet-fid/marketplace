# frozen_string_literal: true

class ApiDocsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def show
    @subsection = extract_subsection
    redirect_to api_docs_path, status: :bad_request if @subsection.nil?
  end

  def create
    regenerate_token
    redirect_to api_docs_path
  end

  private

  def extract_subsection
    subsection = params[:subsection]&.to_sym
    if subsection.blank?
      :introduction
    else
      subsection if helpers.api_wiki_subsections.include? subsection
    end
  end

  def regenerate_token
    current_user.update!(authentication_token: nil)
  end
end
