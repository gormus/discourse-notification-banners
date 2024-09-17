import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import $ from "jquery";
import CookText from "discourse/components/cook-text";
import DButton from "discourse/components/d-button";
import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

export default apiInitializer("1.14.0", (api) => {
  try {
    const splide_css = document.createElement("link");
    splide_css.setAttribute("rel", "stylesheet");
    splide_css.setAttribute("type", "text/css");
    splide_css.setAttribute("id", "splide-css");
    splide_css.setAttribute("href", settings.theme_uploads.splide_css);
    document.head.appendChild(splide_css);

    const current_user = api.getCurrentUser();
    let current_user_groups = [0];
    if (current_user) {
      current_user.groups.filter((group) => {
        current_user_groups.push(group.id);
      });
    }

    const banner_list = settings.banners;

    // 1: Sort by display_order.
    banner_list.sort((a, b) => a.display_order - b.display_order);

    // 2: Display stacked banners first, then carousel banners to group in place.
    banner_list.sort((a, b) => {
      const carouselA = a.carousel === true ? 1 : 0;
      const carouselB = b.carousel === true ? 1 : 0;

      return carouselA - carouselB;
    });

    // 3: Sort by plugin_outlet.
    banner_list.sort((a, b) => {
      const pluginOutletA = a.plugin_outlet.toUpperCase();
      const pluginOutletB = b.plugin_outlet.toUpperCase();
      if (pluginOutletA < pluginOutletB) {
        return -1;
      }
      if (pluginOutletA > pluginOutletB) {
        return 1;
      }
      return 0;
    });

    banner_list.forEach((BANNER, n) => {
      const banner_audience = BANNER.enabled_groups;
      const banner_categories = BANNER.selected_categories;
      const banner_title = BANNER.title?.trim();
      const banner_message = BANNER.message.trim();
      const banner_plugin_outlet = BANNER.plugin_outlet.trim();
      const banner_id = `notification-banner--${n}--${banner_plugin_outlet}`;
      const banner_css_carousel = BANNER.carousel === true ? "carousel" : "";

      api.renderInOutlet(
        banner_plugin_outlet,
        class NotificationBanners extends Component {
          @service store;
          @service router;
          @service siteSettings;
          @tracked
          dismissed = this.bannerDismissable
            ? localStorage.getItem(banner_id)
            : false;

          get showOnRoute() {
            const currentRoute = this.router.currentRoute;
            // Show everywhere but admin pages.
            return !currentRoute.name.includes("admin");
          }

          get showOnCategory() {
            if (banner_categories.length === 0) {
              return true;
            }
            const currentRoute = this.router.currentRoute;
            const category_id = currentRoute.attributes?.category?.id;
            return (
              currentRoute.name === "discovery.category" &&
              banner_categories.includes(category_id)
            );
          }

          get showForCurrentUser() {
            if (banner_audience.includes(0)) {
              return true;
            }
            return banner_audience.some((group) =>
              current_user_groups.includes(group)
            );
          }

          get showBetweenDates() {
            const currentDate = new Date().valueOf();
            const dateAfter = isNaN(Date.parse(BANNER.date_after))
              ? currentDate
              : Date.parse(BANNER.date_after);
            const dateBefore = isNaN(Date.parse(BANNER.date_before))
              ? currentDate
              : Date.parse(BANNER.date_before);
            return currentDate >= dateAfter && currentDate <= dateBefore;
          }

          get bannerColors() {
            const background_color = BANNER.background_color;

            let foregroundColor = "var(--primary)";
            let backgroundColor = "var(--tertiary-low)";
            if (background_color) {
              const r = parseInt(background_color.substring(0, 2), 16);
              const g = parseInt(background_color.substring(2, 4), 16);
              const b = parseInt(background_color.substring(4, 6), 16);

              const srgb = [r / 255, g / 255, b / 255];
              const x = srgb.map((i) => {
                if (i <= 0.04045) {
                  return i / 12.92;
                } else {
                  return Math.pow((i + 0.055) / 1.055, 2.4);
                }
              });

              const L = 0.2126 * x[0] + 0.7152 * x[1] + 0.0722 * x[2];
              foregroundColor = L > 0.179 ? "#000000" : "#FFFFFF";
              backgroundColor = `#${background_color}`;
            }

            return `background: ${backgroundColor}; color: ${foregroundColor};`;
          }

          get bannerDismissable() {
            return BANNER.dismissable === true;
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
            if (!this.bannerDismissable) {
              return;
            }
            this.dismissed = true;
            return localStorage.setItem(banner_id, true);
          }

          <template>
            {{#if this.shouldShow}}
              <div
                id={{banner_id}}
                class="notification-banner
                  {{banner_css_carousel}}
                  {{banner_plugin_outlet}}"
                style={{htmlSafe this.bannerColors}}
              >
                <div class="notification-banner__wrapper wrap">
                  {{#if this.bannerDismissable}}
                    <div class="notification-banner__close">
                      <DButton
                        @icon="times"
                        @action={{this.dismiss}}
                        @title="banner.close"
                        class="btn-transparent close"
                      />
                    </div>
                  {{/if}}
                  <div class="notification-banner__content">
                    {{#if banner_title}}
                      <h2
                        class="notification-banner__header"
                      >{{banner_title}}</h2>
                    {{/if}}
                    <CookText @rawText={{banner_message}} />
                  </div>
                </div>
              </div>
            {{/if}}
          </template>
        }
      );
    });

    document.addEventListener("DOMContentLoaded", function () {
      loadScript(settings.theme_uploads.splide_js).then(() => {
        const outlets = [
          "above-site-header",
          "below-site-header",
          "top-notices",
        ];
        outlets.forEach((outlet) => {
          const carouselBanners = document.querySelectorAll(
            `.notification-banner.carousel.${outlet}`
          );
          if (carouselBanners.length > 1) {
            $(`.notification-banner.carousel.${outlet}`).each(function () {
              $(this).find(".notification-banner__close").remove();
              $(this).removeClass("carousel");
              $(this).wrap(`<li class="splide__slide ${outlet}"></li>`);
            });

            const template = `<div class="splide ${outlet}" role="group" aria-label="Notification banners"><div class="splide__track"><ul class="splide__list"></ul></div></div>`;
            $(`.splide__slide.${outlet}`).wrapAll(template);

            const outlet_name =
              "splide_options__" + outlet.replaceAll("-", "_");
            const outlet_options = JSON.parse(settings[outlet_name]);

            // eslint-disable-next-line no-undef
            new Splide(`.splide.${outlet}`, outlet_options).mount();
          }
        });
      });
    });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(
      e,
      "There is a problem loading the notification-banners initializer."
    );
  }
});
