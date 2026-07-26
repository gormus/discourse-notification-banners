import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import DButton from "discourse/ui-kit/d-button";
import DCookText from "discourse/ui-kit/d-cook-text";

export default class NotificationBanner extends Component {
  @tracked
  dismissed =
    this.args.banner.dismissible && !this.args.inCarousel
      ? (() => {
          try {
            return localStorage.getItem(this.args.banner.id);
          } catch {
            // localStorage may be unavailable (e.g., private browsing mode)
            return null;
          }
        })()
      : false;

  get dismissible() {
    return this.args.banner.dismissible && !this.args.inCarousel;
  }

  @action
  dismiss() {
    if (!this.dismissible) {
      return;
    }
    this.dismissed = true;
    try {
      localStorage.setItem(this.args.banner.id, true);
    } catch {
      // localStorage may be unavailable; silently fail
    }
  }

  get showBanner() {
    return !this.dismissed;
  }

  <template>
    {{#if this.showBanner}}
      <div
        id={{@banner.id}}
        class="notification-banner"
        style={{trustHTML @banner.styles}}
      >
        <div class="notification-banner__wrapper wrap">
          {{#if this.dismissible}}
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
            {{#if @banner.title}}
              <h2 class="notification-banner__header">{{@banner.title}}</h2>
            {{/if}}
            <DCookText @rawText={{@banner.message}} />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
