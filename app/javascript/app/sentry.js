// Browser error tracking (Sentry SDK, GlitchTip server). Active only when
// the page has the sentry-* meta tags (SentryHelper, layouts/_head).
// The SDK reports unhandled JS errors and promise rejections by default.
// The Turbo listeners below add the failures that the server cannot see:
// a frame response without the requested frame shows "Content missing",
// and a fetch error stops a form without a trace.
import * as Sentry from "@sentry/browser";

function meta(name) {
  return document.querySelector(`meta[name="${name}"]`)?.content;
}

const dsn = meta("sentry-dsn");

if (dsn) {
  Sentry.init({
    dsn,
    environment: meta("sentry-environment"),
    release: meta("sentry-release"),
  });

  const userId = meta("sentry-user-id");
  if (userId) {
    Sentry.setUser({ id: userId, uid: meta("sentry-user-uid") });
  }

  document.addEventListener("turbo:frame-missing", (event) => {
    const response = event.detail?.response;
    Sentry.captureMessage("Turbo frame missing", {
      level: "error",
      tags: {
        turbo_frame: event.target?.id,
        response_status: response?.status,
      },
      extra: {
        response_url: response?.url,
        page_url: window.location.href,
      },
    });
  });

  document.addEventListener("turbo:fetch-request-error", (event) => {
    const error = event.detail?.error ?? new Error("Turbo fetch request error");
    Sentry.captureException(error, {
      tags: { turbo_frame: event.target?.id },
      extra: {
        request_url: String(event.detail?.request?.url ?? ""),
        page_url: window.location.href,
      },
    });
  });
}
