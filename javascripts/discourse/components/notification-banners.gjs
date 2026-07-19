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

    loadScript(settings.theme_uploads.splide_js).then(() => {
      if (destroyed) {
        return;
      }
      // eslint-disable-next-line no-undef
      splide = new Splide(element).mount();
    });

    return () => {
      destroyed = true;
      splide?.destroy(true);
    };
  });

  constructor() {
    super(...arguments);
    this.setBanners();
    this.router.on("routeDidChange", this.setBanners);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off("routeDidChange", this.setBanners);
  }

  #filterBanners(banner) {
    const currentRoute = this.router.currentRoute;
    const now = Date.now();

    return (
      !this.#adminRoute(currentRoute) &&
      this.#matchedCategory(banner, currentRoute) &&
      this.#matchedAudience(banner) &&
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

    const categoryId = currentRoute.attributes?.category?.id;

    return (
      currentRoute.name === "discovery.category" &&
      banner.selected_categories?.includes(categoryId)
    );
  }

  #matchedAudience(banner) {
    const audience = banner.enabled_groups ?? [AUTO_GROUPS.everyone.id];

    const userGroups = new Set(this.currentUserGroups);
    for (const groupId of audience) {
      if (userGroups.has(groupId)) {
        return true;
      }
    }
    return false;
  }

  #withinDateRange(banner, now) {
    const startDate = banner.date_after ? Date.parse(banner.date_after) : null;
    const endDate = banner.date_before ? Date.parse(banner.date_before) : null;

    if (startDate && now < startDate) {
      return false;
    }
    if (endDate && now > endDate) {
      return false;
    }

    return true;
  }

  get carouselBanners() {
    if (!this.args.carouselBanners) {
      return [];
    }
    return this.args.carouselBanners.filter(this.#filterBanners.bind(this));
  }

  get soloBanners() {
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
    if (this.carouselBanners.length < 2) {
      this.enabledCarouselBanners = [];
      this.enabledSoloBanners = [...this.soloBanners, ...this.carouselBanners];
    } else {
      this.enabledCarouselBanners = this.carouselBanners;
      this.enabledSoloBanners = this.soloBanners;
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
                <NotificationBanner @banner={{banner}} />
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
