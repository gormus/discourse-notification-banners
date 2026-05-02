export default function migrate(settings) {
  if (!settings.has("banners")) {
    return settings;
  }

  const banners = settings.get("banners");
  const updated = banners.map((banner) => {
    const dismissible = banner.dismissable ?? false;
    delete banner.dismissable;

    return {
      ...banner,
      dismissible,
    };
  });

  settings.set("banners", updated);
  return settings;
}
