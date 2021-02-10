# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/service
#
# !!! We are using last created project_item to show email previews !!!
class ProviderPreview < ActionMailer::Preview
  def new_question
    user = User.last
    ProviderMailer.new_question("john@doe.com", user.full_name, user.email, "TEST", Provider.last)
  end
end
