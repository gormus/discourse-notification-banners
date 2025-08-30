import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import CookText from "discourse/components/cook-text";
import DButton from "discourse/components/d-button";
import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

// Constants
const TL_GROUPS = [10, 11, 12, 13, 14];
const BANNER_OUTLETS = [
  "above-site-header",
  "below-site-header",
  "top-notices",
];

function loadSplideCSS() {
  if (document.getElementById("splide-css")) {
    return;
  }

  const link = document.createElement("link");
  Object.assign(link, {
    rel: "stylesheet",
    type: "text/css",
    id: "splide-css",
    href: settings.theme_uploads.splide_css,
  });
  document.head.appendChild(link);
}

function getUserGroups(currentUser) {
  if (!currentUser) {
    return [0];
  }

  const allGroups = currentUser.groups.map((group) => group.id);
  const tlGroups = allGroups.filter((g) => TL_GROUPS.includes(g));
  const highestTl = tlGroups.length > 0 ? [Math.max(...tlGroups)] : [];
  const nonTlGroups = allGroups.filter((group) => !tlGroups.includes(group));

  return [...highestTl, ...nonTlGroups];
}

function sortBanners(bannerList) {
  return bannerList.sort((a, b) => {
    // Primary: plugin_outlet
    const outletComparison = a.plugin_outlet.localeCompare(b.plugin_outlet);
    if (outletComparison !== 0) {
      return outletComparison;
    }

    // Secondary: carousel (stacked first)
    const carouselComparison = (a.carousel ? 1 : 0) - (b.carousel ? 1 : 0);
    if (carouselComparison !== 0) {
      return carouselComparison;
    }

    // Tertiary: display_order
    return a.display_order - b.display_order;
  });
}

function calculateContrastColor(backgroundColor) {
  if (!backgroundColor) {
    return "var(--primary)";
  }

  const r = parseInt(backgroundColor.substring(0, 2), 16);
  const g = parseInt(backgroundColor.substring(2, 4), 16);
  const b = parseInt(backgroundColor.substring(4, 6), 16);

  const srgb = [r, g, b].map((i) => {
    const normalized = i / 255;
    return normalized <= 0.04045
      ? normalized / 12.92
      : Math.pow((normalized + 0.055) / 1.055, 2.4);
  });

  const luminance = 0.2126 * srgb[0] + 0.7152 * srgb[1] + 0.0722 * srgb[2];
  return luminance > 0.179 ? "#000000" : "#FFFFFF";
}

async function initializeCarousels() {
  await loadScript(settings.theme_uploads.splide_js);

  BANNER_OUTLETS.forEach((outlet) => {
    const carouselBanners = document.querySelectorAll(
      `.notification-banner.carousel.${outlet}`
    );

    if (carouselBanners.length <= 1) {
      return;
    }

    // Process banners for carousel
    carouselBanners.forEach((banner) => {
      // Remove close button and carousel class
      banner.querySelector(".notification-banner__close")?.remove();
      banner.classList.remove("carousel");

      // Wrap in slide element
      const slide = document.createElement("li");
      slide.className = `splide__slide ${outlet}`;
      banner.parentNode.insertBefore(slide, banner);
      slide.appendChild(banner);
    });

    // Create carousel wrapper and wrap slides
    const slides = document.querySelectorAll(`.splide__slide.${outlet}`);
    if (slides.length > 0) {
      // Create wrapper elements
      const splideWrapper = document.createElement("div");
      splideWrapper.className = `splide ${outlet}`;
      splideWrapper.setAttribute("role", "group");
      splideWrapper.setAttribute("aria-label", "Notification banners");

      const splideTrack = document.createElement("div");
      splideTrack.className = "splide__track";

      const splideList = document.createElement("ul");
      splideList.className = "splide__list";

      // Build the structure
      splideTrack.appendChild(splideList);
      splideWrapper.appendChild(splideTrack);

      // Insert wrapper before first slide
      const firstSlide = slides[0];
      firstSlide.parentNode.insertBefore(splideWrapper, firstSlide);

      // Move all slides into the wrapper
      slides.forEach((slide) => {
        splideList.appendChild(slide);
      });
    }

    // Initialize Splide with outlet-specific options
    const optionsKey = `splide_options__${outlet.replaceAll("-", "_")}`;
    const options = JSON.parse(settings[optionsKey] || "{}");

    // eslint-disable-next-line no-undef
    new Splide(`.splide.${outlet}`, options).mount();
  });
}

export default apiInitializer((api) => {
  loadSplideCSS();

  const currentUser = api.getCurrentUser();
  const currentUserGroups = getUserGroups(currentUser);
  const sortedBanners = sortBanners([...settings.banners]);

  // Create banner components
  sortedBanners.forEach((banner, index) => {
    const {
      enabled_groups: audience = [],
      selected_categories: categories = [],
      title,
      message,
      plugin_outlet: outlet,
      carousel = false,
      dismissable = false,
      background_color,
      date_after,
      date_before,
    } = banner;

    const bannerId = `notification-banner--${index}--${outlet}`;
    const bannerTitle = title?.trim();
    const bannerMessage = message.trim();

    class NotificationBanner extends Component {
      @service store;
      @service router;
      @service siteSettings;

      @tracked
      dismissed = dismissable
        ? localStorage.getItem(bannerId) === "true"
        : false;

      get showOnRoute() {
        return !this.router.currentRouteName.startsWith("admin");
      }

      get showOnCategory() {
        if (categories.length === 0) {
          return true;
        }

        const { currentRoute } = this.router;
        const categoryId = currentRoute.attributes?.category?.id;

        return (
          currentRoute.name === "discovery.category" &&
          categories.includes(categoryId)
        );
      }

      get showForCurrentUser() {
        return (
          audience.includes(0) ||
          audience.some((group) => currentUserGroups.includes(group))
        );
      }

      get showBetweenDates() {
        const now = Date.now();
        const startDate = date_after ? Date.parse(date_after) : now;
        const endDate = date_before ? Date.parse(date_before) : now;

        return now >= startDate && now <= endDate;
      }

      get bannerStyles() {
        const backgroundColor = background_color
          ? `#${background_color}`
          : "var(--tertiary-low)";
        const textColor = background_color
          ? calculateContrastColor(background_color)
          : "var(--primary)";

        return `background: ${backgroundColor}; color: ${textColor};`;
      }

      get shouldShow() {
        return (
          this.showOnRoute &&
          this.showOnCategory &&
          this.showForCurrentUser &&
          this.showBetweenDates &&
          !this.dismissed
        );
      }

      @action
      dismiss() {
        if (!dismissable) {
          return;
        }

        this.dismissed = true;
        localStorage.setItem(bannerId, "true");
      }

      <template>
        {{#if this.shouldShow}}
          <div
            id={{bannerId}}
            class="notification-banner {{if carousel 'carousel'}} {{outlet}}"
            style={{htmlSafe this.bannerStyles}}
          >
            <div class="notification-banner__wrapper wrap">
              {{#if dismissable}}
                <div class="notification-banner__close">
                  <DButton
                    @icon="xmark"
                    @action={{this.dismiss}}
                    @title="banner.close"
                    class="btn-transparent close"
                  />
                </div>
              {{/if}}
              <div class="notification-banner__content">
                {{#if bannerTitle}}
                  <h2 class="notification-banner__header">{{bannerTitle}}</h2>
                {{/if}}
                <CookText @rawText={{bannerMessage}} />
              </div>
            </div>
          </div>
        {{/if}}
      </template>
    }

    api.renderInOutlet(outlet, NotificationBanner);
  });

  // Initialize carousels after DOM is ready
  initializeCarousels();
});
