# frozen_string_literal: true

# I know that it looks weird to have module and class prefix the same
# but this is trade off to simplify backoffice policies usage in all
# backoffice controllers. Taka a look into
# app/controllers/backoffice/application_controller.rb where default pundit
# methods are overriden to add :backoffice prefix in automatic way.
class Admin::AdminPolicy < Struct.new(:user, :admin)
  def show?
    user&.admin?
  end
end
