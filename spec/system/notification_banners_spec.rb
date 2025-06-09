# frozen_string_literal: true

RSpec.describe "Notification Banners", system: true do
  let!(:theme_component) { upload_theme_component }
  fab!(:category)
  fab!(:group)
  fab!(:user) { Fabricate(:user, groups: [group]) }
  let(:user_menu) { PageObjects::Components::UserMenu.new }

  SiteSetting.theme_authorized_extensions =
    "wasm|jpg|jpeg|png|woff|woff2|svg|eot|ttf|otf|gif|webp|avif|js|css"

  context "when displaying a notification banner for all users" do
    before do
      # Create a banner visible to all users
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Test Banner",
            "message" => "This is a test banner",
            "background_color" => "ff0000",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => true,
            "date_after" => "",
            "date_before" => "",
            "display_order" => 1,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "should display the banner" do
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Test Banner")
      expect(page).to have_content("This is a test banner")
    end
  end

  context "when a notification banner is dismissable" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Dismiss Me",
            "message" => "Dismissable banner",
            "background_color" => "00ff00",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => true,
            "date_after" => "",
            "date_before" => "",
            "display_order" => 1,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "should allow dismissing the banner" do
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Dismissable banner")
      find(".notification-banner__close .close").click
      expect(page).to have_no_css(".notification-banner", text: "Dismissable banner")
    end
  end

  context "when the defined dates are outside of the range" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Future Banner",
            "message" => "Should not show yet",
            "background_color" => "0000ff",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => 1.day.from_now.iso8601,
            "date_before" => 2.days.from_now.iso8601,
            "display_order" => 1,
          },
        ].to_json,
      )
      theme_component.save!
    end
    it "should not display the banner" do
      visit "/"
      expect(page).to have_no_css(".notification-banner", text: "Future Banner")
    end
  end

  context "if the notification banner uses groups for visibility" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [group.id],
            "selected_categories" => [],
            "title" => "Group Banner",
            "message" => "Visible to group",
            "background_color" => "123456",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
            "display_order" => 1,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "should display the banner only for when the groups match to current user's groups" do
      sign_in(user)
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Group Banner")

      user_menu.sign_out
      visit "/"
      expect(page).to have_no_css(".notification-banner", text: "Group Banner")
    end
  end

  context "if the notification banner uses categories for visibility" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [category.id],
            "title" => "Category Banner",
            "message" => "Only in category",
            "background_color" => "abcdef",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
            "display_order" => 1,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "should display the banner only when visiting the selected categories" do
      visit "/c/#{category.id}"
      expect(page).to have_css(".notification-banner", text: "Category Banner")

      visit "/"
      expect(page).to have_no_css(".notification-banner", text: "Category Banner")
    end
  end
end
