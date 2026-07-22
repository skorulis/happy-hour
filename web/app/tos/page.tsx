import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service | DuskRoute",
  description:
    "Rules of use and disclaimers for duskroute.com, including deal accuracy.",
};

export default function TermsOfServicePage() {
  return (
    <div className="mx-auto w-full max-w-prose flex-1 px-6 py-12 md:py-16">
      <header className="mb-10 space-y-3">
        <p className="text-sm font-medium tracking-[0.2em] text-accent-soft uppercase">
          DuskRoute
        </p>
        <h1 className="text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          Terms of Service
        </h1>
        <p className="text-sm text-muted">Last updated: 22 July 2026</p>
      </header>

      <article className="space-y-8 text-base leading-relaxed text-secondary">
        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Agreement</h2>
          <p>
            DuskRoute is the happy-hour discovery service at{" "}
            <a
              href="https://duskroute.com"
              className="text-accent-soft hover:text-foreground"
            >
              duskroute.com
            </a>
            . It is operated by{" "}
            <a
              href="https://skorulis.com"
              className="text-accent-soft hover:text-foreground"
            >
              skorulis.com
            </a>
            .
          </p>
          <p>
            By using DuskRoute or creating an account, you agree to these Terms
            of Service and our{" "}
            <Link
              href="/privacy"
              className="text-accent-soft hover:text-foreground"
            >
              Privacy Policy
            </Link>
            . If you do not agree, do not use the service.
          </p>
          <p>
            This page describes the rules that apply based on how the product is
            built and operated today. It is not legal advice.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            The service
          </h2>
          <p>
            DuskRoute helps you discover happy-hour and related deals at pubs,
            bars, and similar venues. Information on the site is provided for
            general discovery only. Venues are independent third parties; we do
            not operate those venues or control their offers, opening hours, or
            service.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Accounts</h2>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              Provide accurate account details and keep your login credentials
              secure.
            </li>
            <li>
              Email/password sign-up requires email verification before full
              account use.
            </li>
            <li>
              You are responsible for activity under your account. Contact us if
              you believe it has been compromised.
            </li>
            <li>
              There is currently no in-product account deletion flow. To request
              removal, email{" "}
              <a
                href="mailto:support@duskroute.com"
                className="text-accent-soft hover:text-foreground"
              >
                support@duskroute.com
              </a>
              .
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Acceptable use
          </h2>
          <p>You agree not to:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              Use the service for unlawful purposes or to harm others.
            </li>
            <li>
              Submit false, misleading, infringing, or abusive content
              (including deal submissions, images, and reports).
            </li>
            <li>Impersonate another person or misrepresent your affiliation.</li>
            <li>
              Scrape, harvest, or systematically extract data in a way that
              burdens or interferes with the service, except as allowed by
              ordinary browser use or robots rules we publish.
            </li>
            <li>
              Attempt to disrupt, probe, or circumvent security or access
              controls.
            </li>
            <li>
              Use automated means to create accounts or spam submissions without
              our permission.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Deal and venue information
          </h2>
          <p>
            Deal details on DuskRoute — including times, prices, products,
            conditions, and availability — may be incomplete, out of date, or
            incorrect. Information may come from public sources, automated
            extraction, venue materials, or user contributions, and it can
            change without notice.
          </p>
          <p>
            Always confirm current offers, hours, and conditions with the venue
            before relying on a deal. Venues may refuse service, change prices,
            or cancel promotions at any time.
          </p>
          <p>
            DuskRoute is not responsible for whether a venue honours an offer
            listed on the site, for any loss arising from reliance on deal
            information, or for the quality of products or service at venues.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            User contributions
          </h2>
          <p>
            If you submit deals, images, reports, or other content, you
            represent that you have the rights to do so and that your content
            does not violate law or these terms.
          </p>
          <p>
            You grant DuskRoute a non-exclusive, worldwide, royalty-free licence
            to host, store, display, moderate, edit, and otherwise use your
            contributions in connection with operating and improving the
            service. Submissions may be reviewed, changed, or removed; we do not
            guarantee publication or continued display.
          </p>
          <p>
            Deal images you upload may be stored and served publicly while they
            remain in our storage.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Intellectual property
          </h2>
          <p>
            DuskRoute branding, site design, and software are owned by the
            operator or its licensors. You may not copy, modify, or redistribute
            the service or its branding wholesale without permission, except for
            ordinary personal use of the public site.
          </p>
          <p>
            Venue names, logos, and deal content remain the property of their
            respective owners.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Third-party services
          </h2>
          <p>
            Features may rely on third parties (for example Google for optional
            sign-in and maps, email delivery, hosting, analytics, and error
            monitoring). Their terms and privacy practices apply when you use
            those features. We are not responsible for third-party services we
            do not control.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Disclaimers
          </h2>
          <p>
            The service is provided “as is” and “as available.” To the fullest
            extent permitted by law, we disclaim warranties of merchantability,
            fitness for a particular purpose, and non-infringement. We do not
            warrant that the service will be uninterrupted, error-free, or that
            deal or venue information will be accurate or complete.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Limitation of liability
          </h2>
          <p>
            To the fullest extent permitted by law, DuskRoute and its operator
            are not liable for indirect, incidental, special, consequential, or
            punitive damages, or for any loss of profits, data, or goodwill,
            arising from your use of the service or reliance on deal or venue
            information.
          </p>
          <p>
            Nothing in these terms excludes or limits liability that cannot be
            excluded or limited under applicable Australian consumer law.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Suspension and termination
          </h2>
          <p>
            We may suspend or terminate access, remove content, or take other
            reasonable action if you breach these terms or the Privacy Policy,
            abuse the service, or create legal or operational risk. You may stop
            using the service at any time.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Changes</h2>
          <p>
            We may update these terms from time to time. The “Last updated” date
            at the top of this page will change when we do. Continued use of
            DuskRoute after an update means you accept the revised terms. New
            accounts must agree to the terms in effect at sign-up.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Governing law
          </h2>
          <p>
            These terms are governed by the laws of Australia. Courts in New
            South Wales, Australia have non-exclusive jurisdiction over disputes
            arising from these terms or the service, subject to any rights you
            have that cannot be waived.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Contact</h2>
          <p>
            For questions about these terms, email{" "}
            <a
              href="mailto:support@duskroute.com"
              className="text-accent-soft hover:text-foreground"
            >
              support@duskroute.com
            </a>
            .
          </p>
        </section>

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
