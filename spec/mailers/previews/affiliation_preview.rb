# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/affiliation
class AffiliationPreview < ActionMailer::Preview
  def verification
    user = User.new(first_name: "John", last_name: "Doe",
                    email: "johndoe@email.pl")

    AffiliationMailer.verification(Affiliation.new(token: "secret", user: user))
  end
end
