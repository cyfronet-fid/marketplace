# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/service
#
# !!! We are using last created project_item to show email previews !!!
class ProviderPreview < ActionMailer::Preview
  def new_question
    user = User.last
    ProviderMailer.new_question("john@doe.com", user.full_name, user.email, "TEST", Provider.last)
  end

  def waiting_for_approval
    approval_request = ApprovalRequest.last || ApprovalRequest.new(approvable: Provider.last, user: User.last)
    ProviderMailer.waiting_for_approval(approval_request)
  end

  def approved
    ProviderMailer.approved(Provider.last, "john@doe.com")
  end

  def rejected
    ProviderMailer.rejected(Provider.last, "john@doe.com")
  end

  def changes_requested
    message =
      Message.where(messageable_type: "ApprovalRequest").last ||
      Message.new(
        message: "Please add a logo\nand a public contact.",
        author: User.last,
        author_role: :mediator,
        scope: :user_direct,
        messageable: ApprovalRequest.new(approvable: Provider.last, user: User.last)
      )
    ProviderMailer.changes_requested(message, "john@doe.com")
  end
end
