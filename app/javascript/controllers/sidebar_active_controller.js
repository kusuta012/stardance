import { Controller } from "@hotwired/stimulus";

// Updates the active highlight on the persistent sidebar nav as the user
// navigates around the app. The sidebar element has `data-turbo-permanent`
// so the server-rendered active class isn't refreshed on each Turbo visit;
// this controller derives the active item from `window.location.pathname`
// and toggles `sidebar__nav-link--active` accordingly.
export default class extends Controller {
  connect() {
    this._update = this._update.bind(this);
    this._update();
    document.addEventListener("turbo:load", this._update);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._update);
  }

  _update() {
    const path = window.location.pathname;
    // Page-level override: a controller can render
    // `<meta name="active-nav-slug" content="...">` to force a specific
    // sidebar item active regardless of URL. Used for project show pages,
    // where ownership decides which tab lights up.
    const slugOverride = document
      .querySelector('meta[name="active-nav-slug"]')
      ?.getAttribute("content");

    this.element.querySelectorAll(".sidebar__nav-link").forEach((link) => {
      const active = this._matches(path, link, slugOverride);
      link.classList.toggle("sidebar__nav-link--active", active);
      if (active) {
        link.setAttribute("aria-current", "page");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  _matches(path, link, slugOverride) {
    if (slugOverride) return link.dataset.slug === slugOverride;

    // Per-link override: any path under this prefix counts as active. Used
    // for "my projects" → highlight on any /users/* page.
    const activePrefix = link.dataset.activePrefix;
    if (activePrefix) return path.startsWith(activePrefix);

    // Inert/locked items have no href.
    if (!link.hasAttribute("href")) return false;
    const href = link.getAttribute("href");
    if (!href || href === "#") return false;

    // Use the link's `pathname` so query strings don't
    // break matching.
    const linkPath = link.pathname;
    if (path === linkPath) return true;
    if (linkPath === "/") return false;
    return path.startsWith(linkPath + "/");
  }
}
