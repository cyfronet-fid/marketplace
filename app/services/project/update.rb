# frozen_string_literal: true

class Project::Update
  def initialize(project, params)
    @project = project
    @params = params
  end

  def call
    @project.update_attributes(@params)
  end
end
