import Link from "next/link";
import { SiInstagram, SiUntappd } from "react-icons/si";

const socialLinkClassName =
  "inline-flex items-center gap-1.5 transition-colors hover:text-accent-soft";

export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-border-subtle/80 bg-background/40 backdrop-blur-md">
      <div className="mx-auto flex max-w-4xl flex-col items-center justify-center gap-1 px-4 py-4 md:px-6">
        <p className="text-sm text-muted">
          <Link
            href="/about"
            className="transition-colors hover:text-accent-soft"
          >
            About
          </Link>
          {" | "}
          <Link
            href="/privacy"
            className="transition-colors hover:text-accent-soft"
          >
            Privacy
          </Link>
          {" | "}
          <Link
            href="/tos"
            className="transition-colors hover:text-accent-soft"
          >
            Terms
          </Link>
          {" | "}
          <Link
            href="/contact"
            className="transition-colors hover:text-accent-soft"
          >
            Contact
          </Link>
        </p>
        <p className="text-sm text-muted">
          <a
            href="https://skorulis.com"
            className="transition-colors hover:text-accent-soft"
          >
            © {year} skorulis.com
          </a>
          {" | "}
          <a
            href="https://www.instagram.com/skorulis/"
            target="_blank"
            rel="noopener noreferrer"
            className={socialLinkClassName}
          >
            <SiInstagram aria-hidden className="h-3.5 w-3.5 shrink-0" />
            Instagram
          </a>
          {" | "}
          <a
            href="https://untappd.com/user/Skorulis"
            target="_blank"
            rel="noopener noreferrer"
            className={socialLinkClassName}
          >
            <SiUntappd aria-hidden className="h-3.5 w-3.5 shrink-0" />
            Untappd
          </a>
        </p>
      </div>
    </footer>
  );
}
