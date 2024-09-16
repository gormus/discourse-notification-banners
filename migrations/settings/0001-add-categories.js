export default function migrate(settings) {
  if (settings.has("banners")) {
    const banners = settings.get("banners");
    banners.forEach(banner => {
      banner.selected_categories = [];
    });

    settings.set("banners", banners);
  }
  return settings;
}
