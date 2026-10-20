# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lifecycle operations per variant", :backend do
  {
    Service::Removal => %w[Service::Destroy Service::Delete],
    Offer::Removal => %w[Offer::Destroy Offer::Delete],
    Bundle::Removal => %w[Bundle::Destroy Bundle::Delete],
    Service::PcDelete => %w[Service::PcDelete::Standalone Service::PcDelete::Cascading],
    Service::Suspend => %w[Service::Suspend::Standalone Service::Suspend::Cascading],
    Service::Unpublish => %w[Service::Unpublish::Standalone Service::Unpublish::Cascading],
    Provider::Delete => %w[Provider::Delete::Standalone Provider::Delete::Cascading],
    Provider::Suspend => %w[Provider::Suspend::Standalone Provider::Suspend::Cascading],
    Provider::Unpublish => %w[Provider::Unpublish::Standalone Provider::Unpublish::Cascading],
    Catalogue::Delete => %w[Catalogue::Delete::Standalone Catalogue::Delete::Cascading],
    Catalogue::Suspend => %w[Catalogue::Suspend::Standalone Catalogue::Suspend::Cascading],
    Catalogue::Unpublish => %w[Catalogue::Unpublish::Standalone Catalogue::Unpublish::Cascading],
    Bundle::Unpublish => %w[Bundle::Unpublish::Standalone Bundle::Unpublish::Cascading]
  }.each do |operation, (marketplace_class, pl_and_whitelabel_class)|
    describe operation.name do
      context "when running as marketplace" do
        before { allow(Mp::Variant).to receive(:current).and_return(:marketplace) }

        it "uses #{marketplace_class}" do
          expect(operation.implementation.name).to eq(marketplace_class)
        end
      end

      %i[pl whitelabel].each do |variant|
        context "when running as #{variant}" do
          before { allow(Mp::Variant).to receive(:current).and_return(variant) }

          it "uses #{pl_and_whitelabel_class}" do
            expect(operation.implementation.name).to eq(pl_and_whitelabel_class)
          end
        end
      end
    end
  end
end
