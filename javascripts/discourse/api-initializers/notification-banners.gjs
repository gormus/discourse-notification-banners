import { trustHTML } from "@ember/template";
import { apiInitializer } from "discourse/lib/api";
import { AUTO_GROUPS } from "discourse/lib/constants";
import NotificationBanners from "../components/notification-banners";

// Cache for color calculations to avoid redundant computations
const colorStyleCache = new Map();

// Maximum entries in the color cache to prevent unbounded growth
const MAX_COLOR_CACHE_SIZE = 50;
const HEX_COLOR_REGEX = /^[0-9A-Fa-f]{6}$/;

const normalizeHexColor = (backgroundColor) => {
  if (typeof backgroundColor !== "string") {
    return null;
  }

  const normalized = backgroundColor.trim();
  if (!HEX_COLOR_REGEX.test(normalized)) {
    return null;
  }

  return normalized.toUpperCase();
};

const bannerStyles = (background_color) => {
  const safeBackgroundColor = normalizeHexColor(background_color);

  // Check cache first
  if (colorStyleCache.has(safeBackgroundColor)) {
    return colorStyleCache.get(safeBackgroundColor);
  }

  let foregroundColor = "var(--primary)";
  let backgroundColor = "var(--tertiary-low)";

  if (safeBackgroundColor) {
    const r = parseInt(safeBackgroundColor.substring(0, 2), 16);
    const g = parseInt(safeBackgroundColor.substring(2, 4), 16);
    const b = parseInt(safeBackgroundColor.substring(4, 6), 16);

    const srgb = [r, g, b].map((i) => {
      const normalized = i / 255;
      return normalized <= 0.04045
        ? normalized / 12.92
        : Math.pow((normalized + 0.055) / 1.055, 2.4);
    });

    const L = 0.2126 * srgb[0] + 0.7152 * srgb[1] + 0.0722 * srgb[2];
    foregroundColor = L > 0.179 ? "#000000" : "#FFFFFF";
    backgroundColor = `#${safeBackgroundColor}`;
  }

  const result = trustHTML(
    `background-color: ${backgroundColor}; color: ${foregroundColor};`
  );

  // Evict oldest entry if cache is full
  if (colorStyleCache.size >= MAX_COLOR_CACHE_SIZE) {
    const oldestKey = colorStyleCache.keys().next().value;
    colorStyleCache.delete(oldestKey);
  }

  // Cache the result
  colorStyleCache.set(safeBackgroundColor, result);

  return result;
};

// Utility function to transform outlet name for settings lookup
const normalizeName = (outlet) => {
  return outlet.replaceAll("-", "_");
};

const slugify = (str) => {
  str = str
    .trim() // trim leading/trailing white space
    .replace(/[^a-zA-Z0-9 -]/g, "") // remove any non-alphanumeric characters
    .replace(/\s+/g, "-") // replace spaces with hyphens
    .replace(/-+/g, "-") // remove consecutive hyphens
    .padEnd(6, "0");
  return str;
};

// Validate that a splide options string is valid JSON
const parseSplideOptions = (rawOptions) => {
  if (!rawOptions) {
    return "{}";
  }
  try {
    JSON.parse(rawOptions);
    return rawOptions;
  } catch {
    return "{}";
  }
};

const currentUserGroups = (currentUser) => {
  if (!currentUser) {
    return [AUTO_GROUPS.everyone.id, AUTO_GROUPS.anonymous_users.id];
  }

  const userGroups = (currentUser.groups ?? [])
    .filter((g) => !g.name.startsWith("trust_level_"))
    .map((g) => g.id);

  userGroups.push(AUTO_GROUPS[`trust_level_${currentUser.trust_level}`].id);
  userGroups.push(AUTO_GROUPS.everyone.id);
  userGroups.push(AUTO_GROUPS.logged_in_users.id);

  return userGroups;
};

const matchedAudience = (banner, currentUser) => {
  const audience = banner.enabled_groups ?? [AUTO_GROUPS.everyone.id];

  const userGroups = new Set(currentUserGroups(currentUser));
  for (const groupId of audience) {
    if (userGroups.has(groupId)) {
      return true;
    }
  }
  return false;
};

export default apiInitializer((api) => {
  const currentUser = api.getCurrentUser();
  const matchedAudienceForBanner = (banner) =>
    matchedAudience(banner, currentUser);
  const userBanners = settings.banners.filter((banner) =>
    matchedAudienceForBanner(banner)
  );

  const userProcessedBanners = {};
  userBanners.forEach((banner) => {
    if (!userProcessedBanners[banner.plugin_outlet]) {
      userProcessedBanners[banner.plugin_outlet] = {
        carousel: [],
        solo: [],
      };
    }
    userProcessedBanners[banner.plugin_outlet][
      banner.carousel ? "carousel" : "solo"
    ].push({
      ...banner,
      id: `notification-banner--${slugify(banner.id)}--${settings.banner_config_version}`,
      styles: bannerStyles(banner.background_color),
    });
  });

  Object.keys(userProcessedBanners).forEach((outlet) => {
    const carouselBanners = userProcessedBanners[outlet].carousel;
    const soloBanners = userProcessedBanners[outlet].solo;
    const rawOptions = settings[`splide_options__${normalizeName(outlet)}`];
    const splideOptions = parseSplideOptions(rawOptions);

    api.renderInOutlet(
      outlet,
      <template>
        <NotificationBanners
          @outlet={{outlet}}
          @carouselBanners={{carouselBanners}}
          @soloBanners={{soloBanners}}
          @splideOptions={{splideOptions}}
        />
      </template>
    );
  });
});
