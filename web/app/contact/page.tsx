import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Contact | DuskRoute",
  description:
    "Get in touch with DuskRoute for support or venue inquiries.",
};

export default function ContactPage() {
  return (
    <div className="mx-auto w-full max-w-prose flex-1 px-4 py-12 md:px-6 md:py-16">
      <header className="mb-10 space-y-3">
        <p className="text-sm font-medium tracking-[0.2em] text-accent-soft uppercase">
          DuskRoute
        </p>
        <h1 className="text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          Contact
        </h1>
        <p className="text-base leading-relaxed text-secondary">
          Reach us by email — we&apos;ll get back to you as soon as we can.
        </p>
      </header>

      <article className="space-y-8 text-base leading-relaxed text-secondary">
        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            General support
          </h2>
          <p>
            For product questions, account help, privacy or account-removal
            requests, and feedback, email{" "}
            <a
              href="mailto:support@duskroute.com"
              className="text-accent-soft hover:text-foreground"
            >
              support@duskroute.com
            </a>
            .
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Venues</h2>
          <p>
            If you run a bar or restaurant and want to list, update, or partner
            with DuskRoute, email{" "}
            <a
              href="mailto:venues@duskroute.com"
              className="text-accent-soft hover:text-foreground"
            >
              venues@duskroute.com
            </a>
            .
          </p>
        </section>

        <p>
          We read every message. Replies may take a few days depending on
          volume.
        </p>

        <p className="pt-4">
          <Link
            href="/"
            className="font-medium text-accent-soft hover:text-foreground"
          >
            Back to DuskRoute
          </Link>
        </p>
      </article>
    </div>
  );
}
