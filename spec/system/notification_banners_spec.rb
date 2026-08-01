# frozen_string_literal: true

RSpec.describe "Notification Banners" do
  let!(:theme_component) { upload_theme_component }
  fab!(:category)
  fab!(:group)
  fab!(:user) { Fabricate(:user, groups: [group]) }
  let(:user_menu) { PageObjects::Components::UserMenu.new }

  SiteSetting.theme_authorized_extensions = "js|css"

  context "when displaying a notification banner for all users" do
    before do
      # Create a banner visible to all users
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Test Banner",
            "message" => "This is a test banner",
            "background_color" => "ff0000",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => true,
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

  context "when a notification banner is dismissible" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Dismiss Me",
            "message" => "Dismissible banner",
            "background_color" => "00ff00",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => true,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "should allow dismissing the banner" do
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Dismissible banner")
      find(".notification-banner__close .close").click
      expect(page).to have_no_css(".notification-banner", text: "Dismissible banner")
    end
  end

  context "when a logged-out user visits the forum" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Anonymous Banner",
            "message" => "Visible to anonymous users",
            "background_color" => "888888",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "displays the banner for anonymous users" do
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Anonymous Banner")
    end
  end

  context "when using group targeting for visibility" do
    fab!(:targeted_group, :group)

    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [targeted_group.id],
            "selected_categories" => [],
            "title" => "Group Target Banner",
            "message" => "Visible only to members",
            "background_color" => "aaaaaa",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    fab!(:member_user) { Fabricate(:user, groups: [targeted_group]) }
    fab!(:non_member_user, :user) { Fabricate(:user) }

    it "displays the banner only to users in the targeted group" do
      sign_in(member_user)
      visit "/"
      expect(page).to have_css(".notification-banner", text: "Group Target Banner")

      user_menu.sign_out
      sign_in(non_member_user)
      visit "/"
      expect(page).to have_no_css(".notification-banner", text: "Group Target Banner")

      user_menu.sign_out
      visit "/"
      expect(page).to have_no_css(".notification-banner", text: "Group Target Banner")
    end
  end

  context "when changing routes with carousel banners" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel A",
            "message" => "First carousel slide",
            "background_color" => "aaaaaa",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "id" => "AH-002",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel B",
            "message" => "Second carousel slide",
            "background_color" => "bbbbbb",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "re-initializes the carousel after a route change" do
      visit "/"
      expect(page).to have_css(".splide[aria-roledescription='carousel']")
      expect(page).to have_css(".splide .splide__slide .notification-banner", text: "Carousel A")

      visit "/admin"
      expect(page).to have_no_css(".splide[aria-roledescription='carousel']")

      visit "/"
      expect(page).to have_css(".splide[aria-roledescription='carousel']")
      expect(page).to have_css(".splide .splide__slide .notification-banner", text: "Carousel B")
    end
  end

  context "when the defined dates are outside of the range" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Future Banner",
            "message" => "Should not show yet",
            "background_color" => "0000ff",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [group.id],
            "selected_categories" => [],
            "title" => "Group Banner",
            "message" => "Visible to group",
            "background_color" => "123456",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [category.id],
            "title" => "Category Banner",
            "message" => "Only in category",
            "background_color" => "abcdef",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel One",
            "message" => "First carousel banner content",
            "background_color" => "111111",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "id" => "AH-002",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Carousel Two",
            "message" => "Second carousel banner content",
            "background_color" => "222222",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Single Carousel",
            "message" => "Only one carousel banner so it should render solo",
            "background_color" => "333333",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Above Header",
            "message" => "Banner above the site header",
            "background_color" => "444444",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "id" => "BH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Below Header",
            "message" => "Banner below the site header",
            "background_color" => "555555",
            "plugin_outlet" => "below-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "id" => "TN-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Top Notices",
            "message" => "Banner in top notices",
            "background_color" => "666666",
            "plugin_outlet" => "top-notices",
            "carousel" => false,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "No Admin",
            "message" => "Should not be visible in admin routes",
            "background_color" => "777777",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
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
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Dark BG",
            "message" => "Foreground should be white on dark background",
            "background_color" => "000000",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
          {
            "id" => "BH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Light BG",
            "message" => "Foreground should be black on light background",
            "background_color" => "FFFFFF",
            "plugin_outlet" => "below-site-header",
            "carousel" => false,
            "dismissible" => false,
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

  context "when a banner has an invalid background color" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Invalid Color",
            "message" => "Invalid color must fall back to defaults",
            "background_color" => "12ZZ34",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => "",
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "uses fallback colors when hex is invalid" do
      visit "/"

      banner = find(".notification-banner", text: "Invalid Color", match: :first)
      expect(banner[:style]).to include("background-color: var(--tertiary-low)")
      expect(banner[:style]).to include("color: var(--primary)")
      expect(banner[:style]).not_to include("12ZZ34")
    end
  end

  context "when a banner has out-of-range date bounds" do
    before do
      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Future Start Date",
            "message" => "Start date is in the future so this banner is not yet active",
            "background_color" => "225588",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => 1.day.from_now.iso8601,
            "date_before" => "",
          },
          {
            "id" => "AH-002",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Past End Date",
            "message" => "End date is in the past so this banner has already expired",
            "background_color" => "336699",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => "",
            "date_before" => 1.day.ago.iso8601,
          },
          {
            "id" => "AH-003",
            "enabled_groups" => [0],
            "selected_categories" => [],
            "title" => "Valid Date",
            "message" => "This banner is visible because its date bounds are valid",
            "background_color" => "4477AA",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => 1.day.ago.iso8601,
            "date_before" => 1.day.from_now.iso8601,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "hides banners outside their date range and shows banners within range" do
      visit "/"

      expect(page).to have_no_css(".notification-banner", text: "Future Start Date")
      expect(page).to have_no_css(".notification-banner", text: "Past End Date")
      expect(page).to have_css(".notification-banner", text: "Valid Date")
    end
  end

  context "when multiple filters and carousel rules are combined" do
    fab!(:secondary_category, :category)

    before do
      sign_in(user)

      theme_component.update_setting(
        :banners,
        [
          {
            "id" => "AH-001",
            "enabled_groups" => [group.id],
            "selected_categories" => [category.id],
            "title" => "Category Carousel One",
            "message" => "Group, category, and date matched carousel item one",
            "background_color" => "118833",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => true,
            "date_after" => 1.day.ago.iso8601,
            "date_before" => 1.day.from_now.iso8601,
          },
          {
            "id" => "AH-002",
            "enabled_groups" => [group.id],
            "selected_categories" => [category.id],
            "title" => "Category Carousel Two",
            "message" => "Group, category, and date matched carousel item two",
            "background_color" => "229944",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => true,
            "date_after" => 1.day.ago.iso8601,
            "date_before" => 1.day.from_now.iso8601,
          },
          {
            "id" => "AH-003",
            "enabled_groups" => [group.id],
            "selected_categories" => [secondary_category.id],
            "title" => "Wrong Category",
            "message" => "This should not appear in the primary category route",
            "background_color" => "33AA55",
            "plugin_outlet" => "above-site-header",
            "carousel" => true,
            "dismissible" => true,
            "date_after" => 1.day.ago.iso8601,
            "date_before" => 1.day.from_now.iso8601,
          },
          {
            "id" => "AH-004",
            "enabled_groups" => [group.id],
            "selected_categories" => [category.id],
            "title" => "Expired",
            "message" => "This should not appear because it is out of date",
            "background_color" => "44BB66",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => 3.days.ago.iso8601,
            "date_before" => 2.days.ago.iso8601,
          },
          {
            "id" => "AH-005",
            "enabled_groups" => [group.id],
            "selected_categories" => [category.id],
            "title" => "Solo Matched",
            "message" => "This solo banner should render with the active carousel",
            "background_color" => "55CC77",
            "plugin_outlet" => "above-site-header",
            "carousel" => false,
            "dismissible" => false,
            "date_after" => 1.day.ago.iso8601,
            "date_before" => 1.day.from_now.iso8601,
          },
        ].to_json,
      )
      theme_component.save!
    end

    it "shows only matched banners and hides close buttons in carousel" do
      visit "/c/#{category.id}"

      expect(page).to have_css(".splide[aria-roledescription='carousel']")
      expect(page).to have_css(".splide .notification-banner", text: "Category Carousel One")
      expect(page).to have_css(".splide .notification-banner", text: "Category Carousel Two")
      expect(page).to have_no_css(".splide .notification-banner", text: "Wrong Category")
      expect(page).to have_no_css(".notification-banner", text: "Expired")
      expect(page).to have_css(".notification-banner", text: "Solo Matched")

      expect(page).to have_no_css(".splide .notification-banner__close .close")
    end
  end
end
