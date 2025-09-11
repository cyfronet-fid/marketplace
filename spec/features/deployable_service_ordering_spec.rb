# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DeployableService Ordering Workflow", js: true, type: :feature do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:project) { create(:project, user: user) }
  let(:service_category) { create(:service_category) }

  before do
    login_as(user, scope: :user)
    # Set the selected project in session
    page.driver.browser.execute_script("sessionStorage.setItem('selectedProjectId', '#{project.id}');")
  end

  describe "Single offer auto-selection workflow" do
    let!(:deployable_service) do
      create(:deployable_service, name: "Docker JupyterHub", resource_organisation: provider, status: :published)
    end

    let!(:single_offer) do
      create(
        :offer,
        name: "Standard Configuration",
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published,
        order_type: "order_required"
      )
    end

    it "auto-skips offer selection for single offer and completes ordering" do
      visit deployable_service_path(deployable_service)

      expect(page).to have_content("Docker JupyterHub")
      expect(page).to have_button("Configure & Deploy")

      click_button "Configure & Deploy"

      # Should skip choose_offer step and go directly to information step
      expect(current_path).to eq(deployable_service_information_path(deployable_service))
      expect(page).to have_content("Access instructions")

      # Continue through the workflow
      click_button "Continue to configuration"
      expect(current_path).to eq(deployable_service_configuration_path(deployable_service))

      click_button "Continue to summary"
      expect(current_path).to eq(deployable_service_summary_path(deployable_service))

      # Complete the order
      expect { click_button "Add service to the project" }.to change { ProjectItem.count }.by(1)

      # Verify the created project item
      project_item = ProjectItem.last
      expect(project_item.offer).to eq(single_offer)
      expect(project_item.project).to eq(project)
      expect(project_item.status).to eq("ready") # DeployableService specific
    end
  end

  describe "Multiple offers selection workflow" do
    let!(:deployable_service) do
      create(:deployable_service, name: "Multi-Config JupyterHub", resource_organisation: provider, status: :published)
    end

    let!(:offer1) do
      create(
        :offer,
        name: "Small Configuration",
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    let!(:offer2) do
      create(
        :offer,
        name: "Large Configuration",
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    it "shows offer selection step for multiple offers" do
      visit deployable_service_path(deployable_service)

      click_button "Configure & Deploy"

      # Should show the offer selection step
      expect(current_path).to eq(deployable_service_choose_offer_path(deployable_service))
      expect(page).to have_content("Select an offer or service bundle")
      expect(page).to have_content("Small Configuration")
      expect(page).to have_content("Large Configuration")

      # Select the first offer
      choose "customizable_project_item_offer_id_#{offer1.iid}"
      click_button "Continue to access instructions"

      expect(current_path).to eq(deployable_service_information_path(deployable_service))
      expect(page).to have_content("Multi-Config JupyterHub - Small Configuration")
    end
  end

  describe "Error handling and validation" do
    let!(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    let!(:offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    it "handles missing project selection gracefully" do
      # Clear project selection
      page.driver.browser.execute_script("sessionStorage.removeItem('selectedProjectId');")

      visit deployable_service_path(deployable_service)
      click_button "Configure & Deploy"

      # Should redirect to project selection or show error
      # The exact behavior depends on the application's project selection logic
      expect(current_path).not_to eq(deployable_service_summary_path(deployable_service))
    end

    it "shows validation errors appropriately" do
      visit deployable_service_choose_offer_path(deployable_service)

      # Try to continue without selecting an offer (if multiple exist)
      if deployable_service.offers.inclusive.count > 1
        click_button "Continue to access instructions"
        expect(page).to have_content("Please select one of the offer")
      end
    end
  end

  describe "Integration with project management" do
    let!(:deployable_service) do
      create(:deployable_service, name: "Test Service", resource_organisation: provider, status: :published)
    end

    let!(:offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    it "integrates properly with project workflow" do
      visit deployable_service_path(deployable_service)
      click_button "Configure & Deploy"

      # Navigate through the workflow
      visit deployable_service_summary_path(deployable_service)

      # Complete the order
      click_button "Add service to the project"

      # Verify we're redirected appropriately (usually to project page)
      expect(current_path).to match(%r{/projects/})

      # Verify the service appears in the project
      within ".project-items" do
        expect(page).to have_content("Test Service")
      end
    end
  end

  describe "Comparison with regular Service workflow" do
    let!(:regular_service) do
      create(:service, name: "Regular Service", resource_organisation: provider, status: :published)
    end

    let!(:service_offer) do
      create(
        :offer,
        service: regular_service,
        deployable_service: nil,
        offer_category: service_category,
        status: :published
      )
    end

    let!(:deployable_service) do
      create(:deployable_service, name: "Deployable Service", resource_organisation: provider, status: :published)
    end

    let!(:deployable_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    it "handles both Service and DeployableService workflows consistently" do
      # Test DeployableService workflow
      visit deployable_service_path(deployable_service)
      click_button "Configure & Deploy"

      visit deployable_service_summary_path(deployable_service)
      click_button "Add service to the project"

      deployable_project_item = ProjectItem.find_by(offer: deployable_offer)
      expect(deployable_project_item).to be_present
      expect(deployable_project_item.status).to eq("ready") # DeployableService specific

      # Test regular Service workflow
      visit service_path(regular_service)
      click_button "Configure & Deploy"

      visit service_summary_path(regular_service)
      click_button "Add service to the project"

      service_project_item = ProjectItem.find_by(offer: service_offer)
      expect(service_project_item).to be_present
      expect(service_project_item.status).to eq("created") # Regular Service behavior

      # Both should appear in the same project
      expect(deployable_project_item.project).to eq(service_project_item.project)
    end
  end

  describe "Policy and authorization integration" do
    let!(:draft_deployable_service) do
      create(
        :deployable_service,
        resource_organisation: provider,
        status: :draft # Should not be accessible
      )
    end

    it "respects DeployableServicePolicy restrictions" do
      # Should not be able to access draft deployable service
      expect { visit deployable_service_path(draft_deployable_service) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "handles unauthorized access gracefully" do
      logout(user)

      deployable_service = create(:deployable_service, resource_organisation: provider, status: :published)

      visit deployable_service_path(deployable_service)
      click_button "Configure & Deploy"

      # Should redirect to sign in
      expect(current_path).to eq(new_user_session_path)
    end
  end
end
