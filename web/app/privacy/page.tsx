import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy | DuskRoute",
  description:
    "How DuskRoute collects, uses, and stores data when you use duskroute.com.",
};

export default function PrivacyPage() {
  return (
    <div className="mx-auto w-full max-w-prose flex-1 px-6 py-12 md:py-16">
      <header className="mb-10 space-y-3">
        <p className="text-sm font-medium tracking-[0.2em] text-accent-soft uppercase">
          DuskRoute
        </p>
        <h1 className="text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          Privacy policy
        </h1>
        <p className="text-sm text-muted">Last updated: 22 July 2026</p>
      </header>

      <article className="space-y-8 text-base leading-relaxed text-secondary">
        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Who we are</h2>
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
            This page describes how data is handled today based on how the
            product is built and operated. It is not legal advice.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            What we collect
          </h2>
          <p>Depending on how you use DuskRoute, we may process:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <span className="text-foreground">Account data</span> — name,
              email address, hashed password (for email/password accounts),
              email verification status.
            </li>
            <li>
              <span className="text-foreground">Session data</span> — session
              tokens, expiry, IP address, and user agent stored with your
              signed-in session.
            </li>
            <li>
              <span className="text-foreground">Favorites</span> — deal IDs you
              save. When logged out these stay in your browser; when logged in
              they can also be stored on our servers and synced.
            </li>
            <li>
              <span className="text-foreground">Contributions</span> — deal
              details you submit (title, description, conditions, schedules,
              dates) and any deal images you upload, linked to your account for
              moderation.
            </li>
            <li>
              <span className="text-foreground">Reports</span> — category and
              free-text details about a deal. You can report while logged in or
              anonymously; if signed in, the report may be linked to your
              account.
            </li>
            <li>
              <span className="text-foreground">Analytics device ID</span> — a
              random ID stored in your browser and sent with product analytics
              events. If you are signed in, events may also include your user
              ID.
            </li>
            <li>
              <span className="text-foreground">Approximate location</span> —
              only if you use “near me” and grant browser geolocation
              permission. Coordinates are used for nearby search and are not
              saved as a personal location history on your account.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            How we use data
          </h2>
          <ul className="list-disc space-y-2 pl-5">
            <li>Create and manage accounts, sessions, and email verification.</li>
            <li>Power search, map views, and nearby results.</li>
            <li>Sync and display your favorites.</li>
            <li>
              Moderate user-submitted deals and reports (including showing
              submitter or reporter email to admins).
            </li>
            <li>
              Understand product usage via analytics (for example page views,
              searches, map interactions, and venue opens).
            </li>
            <li>Diagnose errors and reliability issues via error monitoring.</li>
            <li>
              Optionally extract deal details from content you provide using a
              language-model provider when you use deal extraction.
            </li>
          </ul>
          <p>
            We use email for account verification (one-time codes and links). We
            do not operate a marketing newsletter from this product today.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Where data is stored
          </h2>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <span className="text-foreground">Application database</span> —
              Postgres hosted on a DigitalOcean droplet in Sydney (accounts,
              sessions, favorites, deals, reports, and related app data).
            </li>
            <li>
              <span className="text-foreground">Uploaded images</span> —
              Cloudflare R2, served publicly via{" "}
              <span className="text-foreground">images.duskroute.com</span>.
            </li>
            <li>
              <span className="text-foreground">Your browser</span> —
              localStorage and sessionStorage for device ID, local favorites,
              and temporary map navigation state.
            </li>
            <li>
              <span className="text-foreground">Analytics and errors</span> —
              Amplitude (product analytics) and Sentry (error monitoring).
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Third parties
          </h2>
          <p>We rely on these services in the course of running DuskRoute:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <span className="text-foreground">Google</span> — optional OAuth
              sign-in; Google Maps JavaScript API in the browser for map
              features. Venue data may include Google Places identifiers.
            </li>
            <li>
              <span className="text-foreground">Resend</span> — transactional
              verification emails.
            </li>
            <li>
              <span className="text-foreground">Amplitude</span> — product
              analytics.
            </li>
            <li>
              <span className="text-foreground">Sentry</span> — error and
              performance monitoring.
            </li>
            <li>
              <span className="text-foreground">Cloudflare</span> — DNS/CDN and
              R2 object storage for images.
            </li>
            <li>
              <span className="text-foreground">OpenRouter</span> — language
              models used when extracting deal information from user-provided
              images or text.
            </li>
            <li>
              <span className="text-foreground">DigitalOcean</span> — hosting
              for the app and database.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Cookies and local storage
          </h2>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <span className="text-foreground">Session cookies</span> — used
              by our authentication system to keep you signed in.
            </li>
            <li>
              <span className="text-foreground">localStorage</span> — analytics
              device ID (<code className="text-sm text-foreground">dr_device_id</code>
              ) and saved favorite deal IDs when using favorites locally.
            </li>
            <li>
              <span className="text-foreground">sessionStorage</span> —
              temporary map entry state used while navigating between list and
              map views.
            </li>
          </ul>
          <p>
            There is no separate cookie-consent banner in the product today.
            Analytics and error monitoring may run for visitors as described
            above.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Location</h2>
          <p>
            If you choose “near me”, your browser may ask for location
            permission. Coordinates are used to find nearby deals via our API
            and to show your position on the map. We do not keep a history of
            your precise location on your user profile.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            Retention and your choices
          </h2>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              Creating an account or signing in shows a notice that by
              continuing you agree to our{" "}
              <Link
                href="/tos"
                className="text-accent-soft hover:text-foreground"
              >
                Terms of Service
              </Link>{" "}
              and this Privacy Policy.
            </li>
            <li>You can sign out to end your current session.</li>
            <li>You can remove favorites at any time.</li>
            <li>
              You can withdraw your own open deal reports from your profile
              reports area.
            </li>
            <li>
              There is currently no in-product account deletion or data-export
              flow. If you want an account removed, contact us using the details
              below and we will handle the request manually.
            </li>
          </ul>
          <p>
            Analytics and error data retention is controlled by Amplitude and
            Sentry according to their product settings. Uploaded deal images may
            remain publicly reachable by URL while they exist in our storage.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">Contact</h2>
          <p>
            For privacy questions or account removal requests, email{" "}
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
