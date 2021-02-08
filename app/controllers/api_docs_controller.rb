# frozen_string_literal: true

class ApiDocsController < ApplicationController
  before_action :authenticate_user!
  before_action :api_docs_authorization!

  def show
    @subsection = extract_subsection
    if @subsection.nil?
      redirect_to api_docs_path, status: :bad_request
    end
  end

  def create
    unless current_user.valid_token?
      generate_token
    end
    redirect_to api_docs_path
  end

  def destroy
    revoke_token
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

    def generate_token
      current_user.update(authentication_token: User.generate_token)
    end

    def revoke_token
      current_user.update(authentication_token: "revoked")
    end

    def api_docs_authorization!
      authorize :api_docs, :show?
    end
end
