export default function migrate(settings) {
  if (settings.has("banners")) {
    const banners = settings.get("banners");
    banners.forEach((banner) => {
      delete banner.display_order;
    });

    settings.set("banners", banners);
  }
  return settings;
}
