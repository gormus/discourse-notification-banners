import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";
import NotificationBanners from "../components/notification-banners";

// Cache for color calculations to avoid redundant computations
const colorStyleCache = new Map();

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

function bannerStyles(background_color) {
  // Check cache first
  if (colorStyleCache.has(background_color)) {
    return colorStyleCache.get(background_color);
  }

  let foregroundColor = "var(--primary)";
  let backgroundColor = "var(--tertiary-low)";

  if (background_color) {
    const r = parseInt(background_color.substring(0, 2), 16);
    const g = parseInt(background_color.substring(2, 4), 16);
    const b = parseInt(background_color.substring(4, 6), 16);

    const srgb = [r, g, b].map((i) => {
      const normalized = i / 255;
      return normalized <= 0.04045
        ? normalized / 12.92
        : Math.pow((normalized + 0.055) / 1.055, 2.4);
    });

    const L = 0.2126 * srgb[0] + 0.7152 * srgb[1] + 0.0722 * srgb[2];
    foregroundColor = L > 0.179 ? "#000000" : "#FFFFFF";
    backgroundColor = `#${background_color}`;
  }

  const result = `background-color: ${backgroundColor}; color: ${foregroundColor};`;

  // Cache the result
  colorStyleCache.set(background_color, result);

  return result;
}

// Utility function to transform outlet name for settings lookup
function normalizeName(outlet) {
  return outlet.replaceAll("-", "_");
}

function slugify(str) {
  str = str
    .replace(/[^a-zA-Z0-9 -]/g, "") // remove any non-alphanumeric characters
    .replace(/\s+/g, "-") // replace spaces with hyphens
    .replace(/-+/g, "-") // remove consecutive hyphens
    .replace(/^\s+|\s+$/g, ""); // trim leading/trailing white space
  return str;
}

export default apiInitializer((api) => {
  loadSplideCSS();

  const bannerConfigVersion = settings.banner_config_version;

  const banners = [...settings.banners].reduce((acc, banner) => {
    const outlet = banner.plugin_outlet;
    const type = banner.carousel ? "carousel" : "solo";

    // Create new object instead of mutating
    const processedBanner = {
      ...banner,
      id: `notification-banner--${slugify(banner.id)}--${bannerConfigVersion}`,
      styles: bannerStyles(banner.background_color),
    };

    // Initialize outlet if it doesn't exist
    if (!acc[outlet]) {
      acc[outlet] = {
        carousel: [],
        solo: [],
      };
    }

    // Add banner to appropriate array
    acc[outlet][type].push(processedBanner);

    return acc;
  }, {});

  Object.keys(banners).forEach((outlet) => {
    const carouselBanners = banners[outlet].carousel;
    const soloBanners = banners[outlet].solo;
    const splideOptions = settings[`splide_options__${normalizeName(outlet)}`];

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

  loadScript(settings.theme_uploads.splide_js).then(() => {
    const el = document.querySelectorAll(
      ".splide.notification-banners--above-site-header, .splide.notification-banners--below-site-header, .splide.notification-banners--top-notices"
    );
    el.forEach((carousel) => {
      // eslint-disable-next-line no-undef
      new Splide(carousel).mount();
    });
  });
});
