// This file configures the initialization of Sentry on the client.
// The added config here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";
import { getAppVersion } from "@/lib/app-version";

const isDev = process.env.NODE_ENV === "development";

if (!isDev) {
  Sentry.init({
    dsn: "https://0a387a1fd6e6bad6e0ccacf7a86726ea@o4511748559339520.ingest.de.sentry.io/4511748567924816",
    release: getAppVersion(),

    // Define how likely traces are sampled. Adjust this value in production, or use tracesSampler for greater control.
    tracesSampleRate: 1,
    // Enable logs to be sent to Sentry
    enableLogs: true,

    // BrowserApiErrors wraps setTimeout/addEventListener and historically
    // conflicts with the Google Maps JS API (async map.js / marker callbacks).
    integrations: (integrations) =>
      integrations.filter((integration) => integration.name !== "BrowserApiErrors"),

    // Drop uncaught noise originating inside the Maps CDN. Map failures that
    // reach our React tree are still reported via MapErrorBoundary / error.tsx.
    denyUrls: [/maps\.googleapis\.com/i, /maps-api-v3/i],

    dataCollection: {
      // To disable sending user data and HTTP bodies, uncomment the lines below. For more info visit:
      // https://docs.sentry.io/platforms/javascript/guides/nextjs/configuration/options/#dataCollection
      // userInfo: false,
      // httpBodies: [],
    },
  });
}

export const onRouterTransitionStart = isDev
  ? () => {}
  : Sentry.captureRouterTransitionStart;
