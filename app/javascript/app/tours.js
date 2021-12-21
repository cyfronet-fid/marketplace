import Rails from "@rails/ujs";

export function handleTourFor(event) {
  switch (event.detail.action) {
    case "complete":
      handleCompleteFor(event.detail.data);
      break;
    case "cancel":
      handleCancelFor(event.detail.data);
      break;
    case "init":
      handleInitFor(event.detail.data);
      handleStartFor(event.detail.data);
      break;
    default:
      console.warn(`Unrecognized action of tours: ${event.detail.action}`);
  }
}

function handleCancelFor(data) {
  if (data.activation_strategy === "default") {
    Cookies.set(data.cookies_names.skip, "later", { domain: window.location.hostname });
  } else if (data.activation_strategy === "query_param") {
    window.history.pushState(null, "", stripTourParam(window.location));
  }
}

function handleCompleteFor(data) {
  if (data.activation_strategy === "default") {
    // set cookie
    const completedTours = Cookies.get(data.cookies_names.completed);
    const finishedTours = JSON.parse(!!completedTours ? completedTours : "[]");
    Cookies.set(data.cookies_names.completed, [...finishedTours, data.tour_name], { domain: window.location.hostname });

    // create new history record
    if (data.is_logged_in) {
      fetch("/tour_histories", {
        method: "POST",
        headers: {
          "X-CSRF-Token": Rails.csrfToken(),
          "Content-type": "application/json",
        },
        body: JSON.stringify({
          authenticity_token: data.form_authenticity_token,
          controller_name: data.controller_name,
          action_name: data.action_name,
          tour_name: data.tour_name,
        }),
      })
        .then()
        .catch((error) => console.log(error));
    }
  }

  if (!!data.next_tour_link) {
    Turbolinks.visit(data.next_tour_link);
  } else if (data.activation_strategy === "query_param") {
    window.history.pushState(null, "", stripTourParam(window.location));
  }
}

function stripTourParam(location) {
  const url = new URL(location);
  url.searchParams.delete("tour");
  return url;
}

function handleStartFor(data) {
  data.tour.start = (function (start) {
    return function () {
      if (data.steps.length === 0) {
        return;
      }

      if (data.activation_strategy === "default") {
        if (Cookies.get(data.cookies_names.skip, { domain: window.location.hostname })) {
          return;
        }
      }

      const firstStep = data.steps[0];

      if (firstStep.welcome) {
        start();
      } else {
        const elementToAttachTo = document.querySelector(firstStep.attachTo.element);
        if (!!elementToAttachTo) {
          start();
        }
      }
    };
  })(data.tour.start);

  if (!!data.show_welcome_modal) {
    const welcomeModal = $("#welcome-modal");
    welcomeModal.modal("show");
    welcomeModal.on("hidden.bs.modal", () => data.tour.start());
  } else {
    data.tour.start();
  }
}

function handleInitFor(data) {
  if (!data.steps) {
    return;
  }

  data.steps
    .map((step, index) => ({
      id: `step-${index + 1}`,
      classes: !!step["welcome"] ? "tour-welcome" : "",
      title: step["title"],
      text: step["text"],
      advanceOn: !!step["advanceOn"]
        ? { selector: step["advanceOn"]["selector"], event: step["advanceOn"]["event"] }
        : undefined,
      attachTo: !!step["attachTo"]
        ? { element: step["attachTo"]["element"], on: step["attachTo"]["placement"] }
        : undefined,
      showOn: () => (!!step["attachTo"] && !!document.querySelector(step["attachTo"]["element"])) || !step["attachTo"],
      modalOverlayOpeningRadius: 20,
      modalOverlayOpeningPadding: 10,
      when: {
        show: function () {
          const img = document.createElement("div");
          img.classList.add("new-feature");
          const welcomeModalSelector = `[data-shepherd-step-id="${Shepherd.activeTour.currentStep.id}"] .shepherd-content`;
          document.querySelector(welcomeModalSelector).appendChild(img);
        },
      },
      buttons: getBtns(data, step, index),
      canClickTarget: !!step["canClickTarget"],
    }))
    .forEach((step) => data.tour.addStep(step));
}

function getBtns(data, step, index) {
  if (!!step["buttons"] && step["buttons"].length > 0) {
    return step["buttons"].map((button) => {
      switch (button["action"]) {
        case "done":
          return { text: button["text"] || data.buttons_labels.done, action: data.tour.complete };
        case "later":
          return { text: data.buttons_labels.skip, action: data.tour.cancel, classes: "shepherd-button-secondary" };
        case "continue":
          return { text: data.buttons_labels.continue, action: data.tour.next };
        case "next":
          return { text: data.buttons_labels.next, action: data.tour.next };
        case "exit":
          return { text: data.buttons_labels.exit, action: data.tour.cancel, classes: "shepherd-button-secondary" };
      }
    });
  }

  if (index === 0 && step["welcome"]) {
    return [
      { text: data.buttons_labels.take_tour, action: data.tour.next },
      { text: data.buttons_labels.later, action: data.tour.cancel, classes: "close close-link" },
    ];
  }

  if (index < data.steps.length - 1 || !!data.next_tour_link) {
    return [
      { text: data.buttons_labels.skip, action: data.tour.cancel, classes: "close close-link" },
      { text: data.buttons_labels.continue, action: data.tour.next },
    ];
  }

  if (data.feedback) {
    return [
      {
        text: data.buttons_labels.go_to_feedback,
        action: () => {
          data.tour.complete();
          $("#tour-feedback-modal").modal("show");
        },
      },
    ];
  }

  return [{ text: data.buttons_labels.done, action: data.tour.complete }];
}
