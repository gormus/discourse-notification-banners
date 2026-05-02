export default function migrate(settings) {
  if (!settings.has("banners")) {
    return settings;
  }

  const toISOString = (value) => {
    if (!value) {
      return null;
    }
    const timestamp = Date.parse(value);
    if (Number.isNaN(timestamp)) {
      throw new Error(`Migration stopped. Cannot parse date value: "${value}"`);
    }
    return new Date(timestamp).toISOString();
  };

  const banners = settings.get("banners");
  const updated = banners.map((banner) => ({
    ...banner,
    date_after: toISOString(banner.date_after),
    date_before: toISOString(banner.date_before),
  }));

  settings.set("banners", updated);
  return settings;
}
