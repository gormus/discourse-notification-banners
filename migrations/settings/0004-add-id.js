export default function migrate(settings) {
  const addId = (bannerList) => {
    const prefixMap = {
      "top-notices": "TN",
      "above-site-header": "AH",
      "below-site-header": "BH",
    };

    const counters = {};

    return bannerList.map((banner) => {
      const outlet = banner.plugin_outlet;
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

  if (settings.has("banners")) {
    const banners = settings.get("banners");
    const updatedBanners = addId(banners);

    settings.set("banners", updatedBanners);
  }
  return settings;
}
