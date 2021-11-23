# frozen_string_literal: true

shared_examples "messageable" do
  context "messageable" do
    it { is_expected.to have_many(:messages) }

    describe "before_create" do
      it "should have proper conversation_last_seen value" do
        expect(subject.conversation_last_seen).to eq(subject.created_at)
      end
    end

    describe "#new_messages_to_user" do
      it "returns all new messages to user" do
        seen_messages = create_list(:provider_message, 2, messageable: subject)
        subject.update(conversation_last_seen: Time.now)
        messages = create_list(:provider_message, 2, messageable: subject)
        user_messages = create_list(:message, 2, messageable: subject)
        internal_messages = create_list(:provider_message, 2, messageable: subject, scope: "internal")

        new_messages_to_user = subject.new_messages_to_user

        expect(new_messages_to_user).to match_array(messages)
        expect(new_messages_to_user).to_not include(user_messages)
        expect(new_messages_to_user).to_not include(internal_messages)
        expect(new_messages_to_user).to_not include(seen_messages)
      end

      it "return new messages to the user on a brand new messageable" do
        messages = create_list(:provider_message, 2, messageable: subject)
        expect(subject.new_messages_to_user).to match_array(messages)
      end

      it "return no new messages if there aren't any" do
        expect(subject.new_messages_to_user).to be_empty
      end
    end

    describe "#earliest_new_message_to_user" do
      it "returns proper earliest message" do
        create(:provider_message, messageable: subject)
        subject.update(conversation_last_seen: Time.now)
        create(:provider_message, scope: "internal", messageable: subject)
        message = create(:provider_message, messageable: subject)

        expect(subject.earliest_new_message_to_user).to eq(message)
      end

      it "return proper earliest messages on a brand new messageable" do
        message = create(:provider_message, messageable: subject)
        expect(subject.earliest_new_message_to_user).to eq(message)
      end

      it "returns nil if there are no new messages to user" do
        expect(subject.earliest_new_message_to_user).to be_nil
      end
    end
  end
end
