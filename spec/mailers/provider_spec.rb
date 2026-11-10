# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderMailer, type: :mailer, backend: true do
  # The onboarding emails are pl's: their templates and the mailer layout live
  # in customization/pl, which a pl deployment serves through CUSTOMIZATION_PATH.
  around do |example|
    view_paths = described_class.view_paths
    described_class.prepend_view_path(Rails.root.join("customization/pl/views"))
    example.run
  ensure
    described_class.view_paths = view_paths
  end

  before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

  describe "#waiting_for_approval" do
    subject(:mail) { described_class.waiting_for_approval(approval_request) }

    let(:user) { create(:user) }
    let(:provider) { create(:provider, name: "Awesome provider", status: :unpublished) }
    let(:approval_request) { create(:approval_request, approvable: provider, user: user) }
    let(:html_body) { Capybara.string(mail.html_part.body.decoded) }
    let(:provider_url) do
      Rails.application.routes.url_helpers.backoffice_provider_url(provider, host: "localhost:3000")
    end

    it "is sent from EOSC PL" do
      expect(mail[:from].value).to eq("EOSC PL <eosc-noreply@eosc.pl>")
    end

    it "is sent to the submitting user" do
      expect(mail.to).to contain_exactly(user.email)
    end

    it "has the provider name in the subject" do
      expect(mail.subject).to eq("New provider - Awesome provider is waiting for approval")
    end

    it "thanks the user for submitting the provider" do
      expect(html_body).to have_content(/Thanks for submitting\s+Awesome provider\.\s+Our team will review it\./)
    end

    it "explains when resources can be published" do
      expect(html_body).to have_content(
        "You can add resources now, but you can publish them only after the provider is approved."
      )
    end

    it "links the View provider button to the provider page" do
      expect(html_body).to have_link("View provider", href: provider_url)
    end

    it "includes the provider page link in the text part" do
      expect(mail.text_part.body.decoded).to include(provider_url)
    end

    it "shows no logo by default" do
      expect(mail.attachments).to be_empty
    end

    context "with a logo configured" do
      before do
        allow(Rails.configuration).to receive(:mail_logo_path).and_return(
          Rails.root.join("customization/pl/images/eoscpl-email-logo.png")
        )
      end

      it "embeds the logo" do
        expect(mail.attachments.map(&:filename)).to contain_exactly("header_eoscpl-email-logo.png")
      end

      it "shows the logo in the header" do
        expect(html_body).to have_css("img.logo-img[src^='cid:']")
      end
    end
  end

  describe "#approved" do
    subject(:mail) { described_class.approved(provider, "manager@provider.com") }

    let(:provider) { create(:provider, name: "Awesome provider") }
    let(:html_body) { Capybara.string(mail.html_part.body.decoded) }
    let(:resources_url) do
      Rails.application.routes.url_helpers.backoffice_services_url(providers: provider.id, host: "localhost:3000")
    end

    it "is sent from EOSC PL" do
      expect(mail[:from].value).to eq("EOSC PL <eosc-noreply@eosc.pl>")
    end

    it "is sent to the provider manager" do
      expect(mail.to).to contain_exactly("manager@provider.com")
    end

    it "has the provider name in the subject" do
      expect(mail.subject).to eq("Provider - Awesome provider is approved")
    end

    it "confirms the provider is published in EOSC PL" do
      expect(html_body).to have_content(/Awesome provider\s+is now published in EOSC PL\./)
    end

    it "explains that resources are not published automatically" do
      expect(html_body).to have_content(
        "Your resources are not published automatically. Open the list and publish the ones that are ready."
      )
    end

    it "links the Publish resources button to the provider resource list" do
      expect(html_body).to have_link("Publish resources", href: resources_url)
    end

    it "includes the provider resource list link in the text part" do
      expect(mail.text_part.body.decoded).to include(resources_url)
    end
  end

  describe "#rejected" do
    subject(:mail) { described_class.rejected(provider, "manager@provider.com") }

    let(:provider) { create(:provider, name: "Awesome provider", status: :unpublished) }
    let(:html_body) { Capybara.string(mail.html_part.body.decoded) }

    before { allow(Mp::Application.config).to receive(:helpdesk_email).and_return("support@marketplace.test") }

    it "is sent from EOSC PL" do
      expect(mail[:from].value).to eq("EOSC PL <eosc-noreply@eosc.pl>")
    end

    it "is sent to the provider manager" do
      expect(mail.to).to contain_exactly("manager@provider.com")
    end

    it "has the provider name in the subject" do
      expect(mail.subject).to eq("Provider - Awesome provider was not approved")
    end

    it "sends replies to the helpdesk" do
      expect(mail.reply_to).to contain_exactly("support@marketplace.test")
    end

    it "says the provider was reviewed and not approved" do
      expect(html_body).to have_content(/Our team reviewed\s+Awesome provider\s+and did not approve it\./)
    end

    it "explains the provider stays unpublished and hidden" do
      expect(html_body).to have_content("It stays in your account as unpublished, so it is not visible to users.")
    end

    it "invites the manager to write to the configured helpdesk" do
      expect(html_body).to have_content(
        "Write to support@marketplace.test if you want to add missing information or ask about the decision."
      )
    end

    it "links the Contact helpdesk button to the configured helpdesk address" do
      expect(html_body).to have_link("Contact helpdesk", href: "mailto:support@marketplace.test")
    end

    it "includes the helpdesk mailto link in the text part" do
      expect(mail.text_part.body.decoded).to include("mailto:support@marketplace.test")
    end
  end

  describe "#changes_requested" do
    subject(:mail) { described_class.changes_requested(message, "manager@provider.com") }

    let(:provider) { create(:provider, name: "Awesome provider", status: :unpublished) }
    let(:coordinator) { create(:user, roles: [:coordinator], email: "coordinator@marketplace.test") }
    let(:approval_request) { create(:approval_request, approvable: provider) }
    let(:message_text) { "Please add a logo." }
    let(:message) do
      create(:coordinator_message, message: message_text, author: coordinator, messageable: approval_request)
    end
    let(:html_body) { Capybara.string(mail.html_part.body.decoded) }
    let(:provider_url) do
      Rails.application.routes.url_helpers.backoffice_provider_url(provider, host: "localhost:3000")
    end

    before { allow(Mp::Application.config).to receive(:helpdesk_email).and_return("support@marketplace.test") }

    it "is sent from EOSC PL" do
      expect(mail[:from].value).to eq("EOSC PL <eosc-noreply@eosc.pl>")
    end

    it "is sent to the provider manager" do
      expect(mail.to).to contain_exactly("manager@provider.com")
    end

    it "has the provider name in the subject" do
      expect(mail.subject).to eq("Provider - Awesome provider needs more information")
    end

    it "sends replies to the helpdesk" do
      expect(mail.reply_to).to contain_exactly("support@marketplace.test")
    end

    it "says the provider was reviewed" do
      expect(html_body).to have_content(/Our team reviewed\s+Awesome provider\s+and needs this:/)
    end

    it "includes the coordinator message" do
      expect(html_body).to have_css(".coordinator-message", text: "Please add a logo.")
    end

    it "includes the coordinator message in the text part" do
      expect(mail.text_part.body.decoded).to include("Please add a logo.")
    end

    it "asks for a reply or a helpdesk contact" do
      expect(html_body).to have_content(
        "Please reply to the email below with the requested information, " \
          "or contact us through the Helpdesk using the link below."
      )
    end

    it "links the Contact Helpdesk button to the configured helpdesk address" do
      expect(html_body).to have_link("Contact Helpdesk", href: "mailto:support@marketplace.test")
    end

    it "links to the provider form in Marketplace" do
      expect(html_body).to have_link("Awesome provider", href: provider_url)
    end

    context "when the message contains HTML" do
      let(:message_text) { "<script>alert('x')</script><b>Add a logo</b>" }

      it "does not render the HTML" do
        expect(html_body).to have_no_css(".coordinator-message script, .coordinator-message b")
      end

      it "shows the markup as text" do
        expect(html_body).to have_css(".coordinator-message", text: "<b>Add a logo</b>")
      end
    end

    context "when the message has several lines" do
      let(:message_text) { "Please add a logo.\nAnd a public contact." }

      it "keeps the line breaks" do
        expect(html_body).to have_css(".coordinator-message br")
      end

      it "keeps both lines" do
        expect(html_body).to have_css(".coordinator-message", text: /Please add a logo\.\s+And a public contact\./)
      end
    end
  end
end
