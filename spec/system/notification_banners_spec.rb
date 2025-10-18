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

  context "when multiple carousel banners are configured" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel One",
            "message" => "First carousel banner content",
            "background_color" => "111111",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel Two",
            "message" => "Second carousel banner content",
            "background_color" => "222222",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "renders a Splide carousel with two slides" do
      visit "/"
      expect(page).to have_css(".splide[aria-roledescription='carousel']")
      expect(page).to have_css(".splide .splide__slide .notification-banner", text: "Carousel One")
      expect(page).to have_css(".splide .splide__slide .notification-banner", text: "Carousel Two")
    end
  end

  context "when a single carousel banner is configured" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Single Carousel",
            "message" => "Only one carousel banner so it should render solo",
            "background_color" => "333333",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "does not render the carousel container and renders a solo banner instead" do
      visit "/"
      expect(page).to have_no_css(".splide[aria-roledescription='carousel']")
      expect(page).to have_css(".notification-banner", text: "Single Carousel")
    end
  end

  context "when rendering banners in different plugin outlets" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Above Header",
            "message" => "Banner above the site header",
            "background_color" => "444444",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Below Header",
            "message" => "Banner below the site header",
            "background_color" => "555555",
            "plugin_outlet" => "below-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Top Notices",
            "message" => "Banner in top notices",
            "background_color" => "666666",
            "plugin_outlet" => "top-notices",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "displays banners for each configured outlet" do
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Above Header")
      expect(page).to have_css(".notification-banner", text: "Below Header")
      expect(page).to have_css(".notification-banner", text: "Top Notices")
    end
  end

  context "when visiting admin routes" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "No Admin",
            "message" => "Should not be visible in admin routes",
            "background_color" => "777777",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "does not display banners on /admin" do
      visit "/admin"
      expect(page).to have_no_css(".notification-banner", text: "No Admin")
    end
  end

  context "when applying background color styles" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Dark BG",
            "message" => "Foreground should be white on dark background",
            "background_color" => "000000",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Light BG",
            "message" => "Foreground should be black on light background",
            "background_color" => "FFFFFF",
            "plugin_outlet" => "below-site-header",
            "carousel" => false,
            "dismissable" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "sets inline styles for background and foreground color based on luminance" do
      visit "/"

      dark = find(".notification-banner", text: "Dark BG", match: :first)
      expect(dark[:style]).to include("background-color: #000000")
      expect(dark[:style]).to match(/color: #FFFFFF|color: rgb\(255, 255, 255\)/)

      light = find(".notification-banner", text: "Light BG", match: :first)
      expect(light[:style]).to include("background-color: #FFFFFF")
      expect(light[:style]).to match(/color: #000000|color: rgb\(0, 0, 0\)/)
    end
  end
end
