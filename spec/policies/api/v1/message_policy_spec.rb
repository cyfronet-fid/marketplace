# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::MessagePolicy, type: :policy, backend: true do
  subject { described_class }

  let(:oms_admin) { create(:user) }
  let(:default_oms_admin) { create(:user) }

  let(:oms) { create(:oms, administrators: [oms_admin]) }
  let(:default_oms) { create(:default_oms, administrators: [default_oms_admin]) }

  let(:project_item1) { build(:project_item, offer: build(:offer, primary_oms: oms)) }
  let(:project_item2) { build(:project_item, offer: build(:offer, primary_oms: default_oms)) }
  let(:project_item3) { build(:project_item, offer: build(:offer, primary_oms: nil)) }

  let(:project1) { create(:project, project_items: [project_item1, project_item2]) }
  let(:project2) { create(:project, project_items: [project_item3]) }
  let(:project3) { create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))]) }

  let!(:message1) { create(:message, messageable: project1, scope: "public", author_role: "provider") }
  let!(:message2) { create(:message, messageable: project1, scope: "public", author_role: "mediator") }
  let!(:message3) { create(:message, messageable: project2, scope: "internal", author_role: "provider") }
  let!(:message4) { create(:message, messageable: project2, scope: "internal", author_role: "mediator") }
  let!(:message5) { create(:message, messageable: project3, scope: "user_direct", author_role: "provider") }
  let!(:message6) { create(:message, messageable: project3, scope: "user_direct", author_role: "mediator") }
  let!(:message7) { create(:message, messageable: project3, author_role: "user") }

  let!(:message8) { create(:message, messageable: project_item1, scope: "public", author_role: "provider") }
  let!(:message9) { create(:message, messageable: project_item1, scope: "public", author_role: "mediator") }
  let!(:message10) { create(:message, messageable: project_item2, scope: "internal", author_role: "provider") }
  let!(:message11) { create(:message, messageable: project_item2, scope: "internal", author_role: "mediator") }
  let!(:message12) { create(:message, messageable: project_item3, scope: "user_direct", author_role: "provider") }
  let!(:message13) { create(:message, messageable: project_item3, scope: "user_direct", author_role: "mediator") }
  let!(:message14) { create(:message, messageable: project_item3, author_role: "user") }

  permissions ".scope" do
    it "shows all project's and project_items' messages when user is a default oms admin" do
      expect(subject::Scope.new(default_oms_admin, project1.messages).resolve).to contain_exactly(message1, message2)
      expect(subject::Scope.new(default_oms_admin, project2.messages).resolve).to contain_exactly(message3, message4)
      expect(subject::Scope.new(default_oms_admin, project3.messages).resolve).to contain_exactly(
        message5,
        message6,
        message7
      )

      expect(subject::Scope.new(default_oms_admin, project_item1.messages).resolve).to contain_exactly(
        message8,
        message9
      )
      expect(subject::Scope.new(default_oms_admin, project_item2.messages).resolve).to contain_exactly(
        message10,
        message11
      )
      expect(subject::Scope.new(default_oms_admin, project_item3.messages).resolve).to contain_exactly(
        message12,
        message13,
        message14
      )
    end

    it "shows messages which offers' primary_oms is administrated by user" do
      expect(subject::Scope.new(oms_admin, project1.messages).resolve).to contain_exactly(message1, message2)
      expect(subject::Scope.new(oms_admin, project2.messages).resolve).to eq([])
      expect(subject::Scope.new(oms_admin, project3.messages).resolve).to contain_exactly(message5, message6, message7)

      expect(subject::Scope.new(oms_admin, project_item1.messages).resolve).to contain_exactly(message8, message9)
      expect(subject::Scope.new(oms_admin, project_item2.messages).resolve).to eq([])
      expect(subject::Scope.new(oms_admin, project_item3.messages).resolve).to eq([])
    end
  end

  permissions :show? do
    it "grants permission to all of the project's and project_items' messages when user is a default oms admin" do
      expect(subject).to permit(default_oms_admin, message1)
      expect(subject).to permit(default_oms_admin, message2)
      expect(subject).to permit(default_oms_admin, message3)
      expect(subject).to permit(default_oms_admin, message4)
      expect(subject).to permit(default_oms_admin, message5)
      expect(subject).to permit(default_oms_admin, message6)
      expect(subject).to permit(default_oms_admin, message7)
      expect(subject).to permit(default_oms_admin, message8)
      expect(subject).to permit(default_oms_admin, message9)
      expect(subject).to permit(default_oms_admin, message10)
      expect(subject).to permit(default_oms_admin, message11)
      expect(subject).to permit(default_oms_admin, message12)
      expect(subject).to permit(default_oms_admin, message13)
      expect(subject).to permit(default_oms_admin, message14)
    end

    it "grants permission to project's and project_items' messages when user is a provider oms admin" do
      expect(subject).to permit(oms_admin, message1)
      expect(subject).to permit(oms_admin, message2)
      expect(subject).to_not permit(oms_admin, message3)
      expect(subject).to_not permit(oms_admin, message4)
      expect(subject).to permit(oms_admin, message5)
      expect(subject).to permit(oms_admin, message6)
      expect(subject).to permit(oms_admin, message7)
      expect(subject).to permit(oms_admin, message8)
      expect(subject).to permit(oms_admin, message9)
      expect(subject).to_not permit(oms_admin, message10)
      expect(subject).to_not permit(oms_admin, message11)
      expect(subject).to_not permit(oms_admin, message12)
      expect(subject).to_not permit(oms_admin, message13)
      expect(subject).to_not permit(oms_admin, message14)
    end
  end

  permissions :create?, :update? do
    it "grants permission to project's messages" do
      expect(subject).to permit(default_oms_admin, message1)
      expect(subject).to permit(oms_admin, message1)

      expect(subject).to permit(default_oms_admin, message2)
      expect(subject).to_not permit(oms_admin, message2)

      expect(subject).to permit(default_oms_admin, message3)
      expect(subject).to_not permit(oms_admin, message3)

      expect(subject).to permit(default_oms_admin, message4)
      expect(subject).to_not permit(oms_admin, message4)

      expect(subject).to_not permit(default_oms_admin, message5)
      expect(subject).to_not permit(oms_admin, message5)

      expect(subject).to permit(default_oms_admin, message6)
      expect(subject).to_not permit(oms_admin, message6)

      expect(subject).to_not permit(oms_admin, message7)
      expect(subject).to_not permit(oms_admin, message7)
    end

    it "grants permission to project item's messages" do
      expect(subject).to_not permit(default_oms_admin, message8)
      expect(subject).to permit(oms_admin, message8)

      expect(subject).to permit(default_oms_admin, message9)
      expect(subject).to_not permit(oms_admin, message9)

      expect(subject).to permit(default_oms_admin, message10)
      expect(subject).to_not permit(oms_admin, message10)

      expect(subject).to permit(default_oms_admin, message11)
      expect(subject).to_not permit(oms_admin, message11)

      expect(subject).to permit(default_oms_admin, message12)
      expect(subject).to_not permit(oms_admin, message12)

      expect(subject).to_not permit(default_oms_admin, message13)
      expect(subject).to_not permit(oms_admin, message13)

      expect(subject).to_not permit(default_oms_admin, message14)
      expect(subject).to_not permit(oms_admin, message14)
    end
  end
end
