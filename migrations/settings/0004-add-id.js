export default function migrate(settings) {
  if (!settings.has("banners")) {
    return settings;
  }

  const addId = (bannerList) => {
    const prefixMap = {
      "top-notices": "TN",
      "above-site-header": "AH",
      "below-site-header": "BH",
    };

    const counters = {};

    return bannerList.map((banner) => {
      const outlet = banner.plugin_outlet;
      if (!outlet || !(outlet in prefixMap)) {
        throw new Error(
          `Migration stopped. Banner has an invalid plugin_outlet: "${outlet}". Expected one of: ${Object.keys(prefixMap).join(", ")}.`
        );
      }

      const prefix = prefixMap[outlet];

      if (!counters[outlet]) {
        counters[outlet] = 0;
      }

      counters[outlet]++;
      const id = `${prefix}-${counters[outlet].toString().padStart(3, "0")}`;

      return {
        id,
        ...banner,
      };
    });
  };

  const banners = settings.get("banners");
  const updatedBanners = addId(banners);

  settings.set("banners", updatedBanners);
  return settings;
}
