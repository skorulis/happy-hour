export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-border-subtle/80 bg-background/40 backdrop-blur-md">
      <div className="mx-auto flex max-w-4xl items-center justify-center px-4 py-4 md:px-6">
        <a
          href="https://skorulis.com"
          className="text-sm text-muted transition-colors hover:text-accent-soft"
        >
          © {year} skorulis.com
        </a>
      </div>
    </footer>
  );
}
