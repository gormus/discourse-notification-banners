export default function migrate(settings) {
  if (settings.has("banners")) {
    const banners = settings.get("banners");
    banners.forEach((banner) => {
      banner.dismissible = banner.dismissable;
      delete banner.dismissable;
    });

    settings.set("banners", banners);
  }
  return settings;
}
