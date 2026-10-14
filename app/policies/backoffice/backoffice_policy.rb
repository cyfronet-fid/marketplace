# frozen_string_literal: true

# I know that it looks weird to have module and class prefix the same
# but this is trade off to simplify backoffice policies usage in all
# backoffice controllers. Taka a look into
# app/controllers/backoffice/application_controller.rb where default pundit
# methods are overriden to add :backoffice prefix in automatic way.
Backoffice::BackofficePolicy =
  Struct.new(:user, :backoffice) do
    def show?
      # Only pl opens the backoffice to executives and admins (pl-marketplace #178).
      (Mp::Variant.pl? && (user&.executive? || user&.admin?)) || user&.coordinator? || user&.data_administrator?
    end
  end
