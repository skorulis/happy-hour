export function getAppVersion(): string {
  const version = process.env.NEXT_PUBLIC_APP_VERSION?.trim();
  return version && version.length > 0 ? version : "debug";
}
