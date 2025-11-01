export default function migrate(settings) {
  if (settings.has("banners")) {
    const banners = settings.get("banners");
    // Sort banners by display_order (ascending)
    banners.sort((a, b) => a.display_order - b.display_order);

    settings.set("banners", banners);
  }
  return settings;
}
