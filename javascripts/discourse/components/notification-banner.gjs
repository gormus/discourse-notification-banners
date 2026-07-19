import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import DButton from "discourse/ui-kit/d-button";
import DCookText from "discourse/ui-kit/d-cook-text";

export default class NotificationBanner extends Component {
  @tracked
  dismissed = this.args.banner.dismissible
    ? localStorage.getItem(this.args.banner.id)
    : false;

  @action
  dismiss() {
    if (!this.args.banner.dismissible) {
      return;
    }
    this.dismissed = true;
    return localStorage.setItem(this.args.banner.id, true);
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
          {{#if @banner.dismissible}}
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
