import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import CookText from "discourse/components/cook-text";
import DButton from "discourse/components/d-button";

export default class NotificationBanner extends Component {
  @tracked
  dismissed = this.args.banner.dismissable
    ? localStorage.getItem(this.args.banner.id)
    : false;

  @action
  dismiss() {
    if (!this.args.banner.dismissable) {
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
        style={{htmlSafe @banner.styles}}
      >
        <div class="notification-banner__wrapper wrap">
          {{#if @banner.dismissable}}
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
            <CookText @rawText={{@banner.message}} />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
