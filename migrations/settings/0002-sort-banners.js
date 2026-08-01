export default function migrate(settings) {
  if (!settings.has("banners")) {
    return settings;
  }

  const banners = settings.get("banners");

  // Validate that display_order values are present and numeric
  for (const banner of banners) {
    if (banner.display_order == null || typeof banner.display_order !== "number") {
      throw new Error(
        `Migration stopped. Banner with id "${banner.id || "unknown"}" has an invalid or missing display_order value.`
      );
    }
  }

  // Sort banners by display_order (ascending)
  banners.sort((a, b) => a.display_order - b.display_order);

  settings.set("banners", banners);
  return settings;
}
