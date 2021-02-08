# frozen_string_literal: true

class ApiDocsPolicy < Struct.new(:user, :api_docs)
  def show?
    user.data_administrator?
  end
end
