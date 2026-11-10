import "cookieconsent/build/cookieconsent.min";

export default function initCookiesPolicy() {
  window.cookieconsent.initialise({
    palette: {
      popup: {
        background: "#1b303a",
      },
      button: {
        background: "#14a7d0",
      },
    },
    theme: "classic",
    content: {
      dismiss: "I agree",
      link: "privacy policy.",
      href: "https://eosc-portal.eu/privacy-policy-summary",
    },
    elements: {
      dismiss:
        '<a aria-label="dismiss cookie message" tabindex="0" class="btn btn-primary btn-close cc-dismiss cc-btn">{{dismiss}}</a>',
      messagelink: `
          <span id="cookieconsent:desc" class="cc-message">
            We use browser cookies to give you the best possible experience.
            To learn more about what data we collect and for what purporse,
            please check our
            <a aria-label="learn more about cookies" role=button tabindex="0"
               class="cc-link" href="{{href}}"
               rel="noopener noreferrer nofollow" target="{{target}}">
               {{link}}
            </a>
            By browsing this website you automatically consent to us recording
            data according to this policy.
          </span>
        `,
    },
  });
}
