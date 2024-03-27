import { Controller } from "@hotwired/stimulus";
import Fuse from "fuse.js";

export default class extends Controller {
  static targets = ["element", "toggler", "item", "search", "all"];
  alwaysShow = 5;

  connect() {
    if (this.hasSearchTarget) {
      this.initSearchElements();
      this.search();
    } else {
      this.limitElements(this.isAll());
    }
  }

  initSearchElements() {
    const candidates = this.itemTargets.map(function (item) {
      return { item: item, title: item.getElementsByTagName("span")[0].textContent };
    });

    const options = {
      keys: ["title"],
      distance: 100,
      minMatchCharLength: 3,
      threshold: 0.3,
    };
    this.fuse = new Fuse(candidates, options);
  }

  search() {
    const result = this.searchResult();
    const show = function (item) {
      return (
        item.querySelector("input").checked ||
        result.includes(item) ||
        Array.from(item.getElementsByTagName("li")).some((e) => result.includes(e) || e.querySelector("input").checked)
      );
    };

    this.itemTargets.forEach((i) => (show(i) ? i.classList.remove("d-none") : i.classList.add("d-none")));

    this.limitElements(this.isAll());
  }

  searchResult() {
    if (this.isSearching()) {
      return this.fuse.search(this.searchTarget.value).map((r) => r["item"]);
    } else {
      return this.itemTargets;
    }
  }

  toggle() {
    this.allTarget.value = this.isAll() ? "false" : "true";
    if (this.hasSearchTarget) {
      this.search();
    } else {
      this.limitElements(this.isAll());
    }
  }

  isAll() {
    return this.allTarget.value == "true";
  }

  limitElements(all) {
    if (this.allTarget.value == "true") {
      this.more(this.elements(), this.togglerTarget);
    } else {
      this.less(this.elements(), this.togglerTarget);
    }
  }

  elements() {
    if (this.isSearching()) {
      return this.elementTargets.filter((e) => !e.classList.contains("d-none"));
    } else {
      return this.elementTargets;
    }
  }

  more(targets, toggler) {
    const extraElements = targets.length - this.alwaysShow;

    if (extraElements <= 0) {
      toggler.classList.add("d-none");
    } else {
      toggler.textContent = "Show less";
      toggler.classList.remove("d-none");
      targets.forEach((el) => el.classList.remove("d-none"));
    }

    return true;
  }

  less(targets, toggler) {
    let extraElements = targets.length - this.alwaysShow;

    const show = function (item) {
      return (
        item.querySelector("input").checked ||
        Array.from(item.getElementsByTagName("li")).some((e) => e.querySelector("input").checked)
      );
    };

    if (extraElements <= 0) {
      toggler.classList.add("d-none");
    } else {
      targets.forEach((el, i) => {
        if (i >= this.alwaysShow) {
          if (show(el)) {
            --extraElements;
          } else {
            el.classList.add("d-none");
          }
        }
      });
      toggler.textContent = `Show ${extraElements} more`;
      toggler.classList.remove("d-none");
    }

    return false;
  }

  isSearching() {
    return this.searchValue().length > 0;
  }

  searchValue() {
    return this.hasSearchTarget ? this.searchTarget.value.trim() : "";
  }
}
