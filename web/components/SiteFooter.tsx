export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-zinc-200 dark:border-zinc-800">
      <div className="mx-auto flex max-w-4xl items-center justify-center px-4 py-4 md:px-6">
        <a
          href="https://skorulis.com"
          className="text-sm text-zinc-500 transition-colors hover:text-amber-700 dark:text-zinc-400 dark:hover:text-amber-400"
        >
          © {year} skorulis.com
        </a>
      </div>
    </footer>
  );
}
