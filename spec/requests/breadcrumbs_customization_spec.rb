# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Breadcrumbs from the customization directory", :backend do
  let(:customization_dir) { Dir.mktmpdir("customization") }
  let(:breadcrumbs_file) { File.join(customization_dir, "config", "breadcrumbs", "marketplace.rb") }
  let!(:original_paths) { Gretel.breadcrumb_paths.dup }
  let!(:original_customization_path) { ENV.fetch("CUSTOMIZATION_PATH", nil) }

  before do
    FileUtils.mkdir_p(File.dirname(breadcrumbs_file))
    File.write(breadcrumbs_file, <<~RUBY)
      crumb :marketplace_root do
        link "Customized start page", root_path
      end
    RUBY
    ENV["CUSTOMIZATION_PATH"] = customization_dir
    load Rails.root.join("config/initializers/breadcrumbs.rb")
    Gretel::Crumbs.reset!
    get about_path
  end

  after do
    if original_customization_path
      ENV["CUSTOMIZATION_PATH"] = original_customization_path
    else
      ENV.delete("CUSTOMIZATION_PATH")
    end
    Gretel.breadcrumb_paths = original_paths
    Gretel::Crumbs.reset!
    FileUtils.remove_entry(customization_dir)
  end

  it "replaces the crumb the customization redefines" do
    expect(response.body).to include("Customized start page")
  end

  it "keeps the crumbs the customization does not redefine" do
    expect(response.body).to include("About Marketplace")
  end
end
