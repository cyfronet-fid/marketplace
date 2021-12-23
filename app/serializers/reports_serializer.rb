# frozen_string_literal: true

class ReportsSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(model)
    model.is_a? Report
  end

  def serialize(report)
    super({ "author" => report.author, "email" => report.email, "text" => report.text })
  end

  def deserialize(hash)
    Report.new(author: hash["author"], email: hash["email"], text: hash["text"])
  end
end
