# frozen_string_literal: true

class PagesController < ApplicationController
  def about
  end

  def about_projects
  end

  def providers
    @providers = Provider.all.order(:name)
  end

  def communities
    @platforms = Platform.all.order(:name)
  end
end
