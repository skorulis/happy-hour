const ADMIN_EMAIL = "skorulis@gmail.com";

export function isAdmin(email: string): boolean {
  return email === ADMIN_EMAIL;
}
