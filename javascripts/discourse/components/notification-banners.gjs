import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { AUTO_GROUPS } from "discourse/lib/constants";
import loadScript from "discourse/lib/load-script";
import NotificationBanner from "./notification-banner";

export default class NotificationBanners extends Component {
  @service currentUser;
  @service router;

  @tracked enabledCarouselBanners = [];
  @tracked enabledSoloBanners = [];

  setupSplide = modifier((element) => {
    // The carouselKey argument (passed in the template) is read here so this
    // modifier tears down and re-mounts Splide whenever the set of visible
    // carousel banners changes (e.g. on route changes). This keeps Splide in
    // sync with the DOM that Ember renders from the {{#each}} below.
    let splide;
    let destroyed = false;

    loadScript(settings.theme_uploads.splide_css, { css: true });
    loadScript(settings.theme_uploads.splide_js)
      .then(() => {
        if (destroyed) {
          return;
        }
        // eslint-disable-next-line no-undef
        splide = new Splide(element).mount();
      })
      .catch(() => {
        // Splide failed to load; silently skip — no carousel will render
      });

    return () => {
      destroyed = true;
      splide?.destroy(true);
    };
  });
  // Cached reference for proper router listener binding/unbinding
  _boundSetBanners = null;

  constructor() {
    super(...arguments);
    this._boundSetBanners = this.setBanners.bind(this);
    this.setBanners();
    this.router.on("routeDidChange", this._boundSetBanners);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off("routeDidChange", this._boundSetBanners);
  }

  #filterBanners(banner) {
    const currentRoute = this.router.currentRoute;
    const now = Date.now();

    return (
      !this.#adminRoute(currentRoute) &&
      this.#matchedCategory(banner, currentRoute) &&
      this.#withinDateRange(banner, now)
    );
  }

  #adminRoute(currentRoute) {
    return currentRoute.name?.startsWith("admin");
  }

  #matchedCategory(banner, currentRoute) {
    if (
      !("selected_categories" in banner) ||
      banner.selected_categories?.length === 0
    ) {
      return true;
    }

    // Category-targeted banners only display when the user is on the exact
    // category page — they will not appear on the home page or other routes,
    // even if the user belongs to the target category.
    const categoryId = currentRoute.attributes?.category?.id;

    return (
      currentRoute.name === "discovery.category" &&
      banner.selected_categories?.includes(categoryId)
    );
  }

  #withinDateRange(banner, now) {
    const hasStartDate =
      typeof banner.date_after === "string" && banner.date_after;
    const hasEndDate =
      typeof banner.date_before === "string" && banner.date_before;
    const startDate = hasStartDate ? Date.parse(banner.date_after) : null;
    const endDate = hasEndDate ? Date.parse(banner.date_before) : null;

    // If a date bound is configured but invalid, fail closed to avoid accidental overexposure.
    if (hasStartDate && !Number.isFinite(startDate)) {
      return false;
    }

    if (hasEndDate && !Number.isFinite(endDate)) {
      return false;
    }

    if (Number.isFinite(startDate) && now < startDate) {
      return false;
    }

    if (Number.isFinite(endDate) && now > endDate) {
      return false;
    }

    return true;
  }

  @cached
  get carouselBannersFiltered() {
    if (!this.args.carouselBanners) {
      return [];
    }
    return this.args.carouselBanners.filter(this.#filterBanners.bind(this));
  }

  @cached
  get soloBannersFiltered() {
    if (!this.args.soloBanners) {
      return [];
    }
    return this.args.soloBanners.filter(this.#filterBanners.bind(this));
  }

  @cached
  get currentUserGroups() {
    if (!this.currentUser) {
      return [AUTO_GROUPS.everyone.id, AUTO_GROUPS.anonymous_users.id];
    }

    const userGroups = (this.currentUser.groups ?? [])
      .filter((g) => !g.name.startsWith("trust_level_"))
      .map((g) => g.id);

    userGroups.push(
      AUTO_GROUPS[`trust_level_${this.currentUser.trust_level}`].id
    );
    userGroups.push(AUTO_GROUPS.everyone.id);
    userGroups.push(AUTO_GROUPS.logged_in_users.id);

    return userGroups;
  }

  get carouselKey() {
    return this.enabledCarouselBanners.map((banner) => banner.id).join(",");
  }

  @action
  setBanners() {
    const carouselBanners = this.carouselBannersFiltered;
    const soloBanners = this.soloBannersFiltered;

    if (carouselBanners.length < 2) {
      this.enabledCarouselBanners = [];
      this.enabledSoloBanners = [...soloBanners, ...carouselBanners];
    } else {
      this.enabledCarouselBanners = carouselBanners;
      this.enabledSoloBanners = soloBanners;
    }
  }

  <template>
    {{#if this.enabledCarouselBanners.length}}
      <section
        class="splide notification-banners--{{@outlet}}"
        aria-label="Notification banners"
        aria-roledescription="carousel"
        role="group"
        data-splide={{@splideOptions}}
        {{this.setupSplide this.carouselKey}}
      >
        <div class="splide__track">
          <ul class="splide__list">
            {{#each this.enabledCarouselBanners as |banner|}}
              <li class="splide__slide">
                <NotificationBanner @banner={{banner}} @inCarousel={{true}} />
              </li>
            {{/each}}
          </ul>
        </div>
      </section>
    {{/if}}

    {{#if this.enabledSoloBanners.length}}
      <section class="notification-banners--{{@outlet}}">
        {{#each this.enabledSoloBanners as |banner|}}
          <NotificationBanner @banner={{banner}} />
        {{/each}}
      </section>
    {{/if}}
  </template>
}
