# frozen_string_literal: true

module OMSDataExport
  class Serialize
    def initialize; end

    def call
      {
        project_items: ProjectItem.all.map { |obj| ProjectItemSerializer.new(obj).as_json },
        projects: Project.all.map { |obj| ProjectSerializer.new(obj).as_json },
        comments: Message.all.map { |obj| CommentSerializer.new(obj).as_json }
      }.as_json
    end
  end
end
