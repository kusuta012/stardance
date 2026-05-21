import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    message: String,
    position: { type: String, default: "right" },
  };

  connect() {
    this.boundShow = this.show.bind(this);
    this.boundHide = this.hide.bind(this);
    this.boundOutsideClick = this.handleOutsideClick.bind(this);
    this.boundKey = this.handleKey.bind(this);
    this.boundReposition = this.reposition.bind(this);

    // Hover-capable pointers get hover/focus reveal; coarse-pointer (touch)
    // devices fall back to tap-to-toggle, since hover semantics don't apply.
    this.hoverCapable = window.matchMedia?.("(hover: hover)")?.matches ?? false;

    if (this.hoverCapable) {
      this.element.addEventListener("mouseenter", this.boundShow);
      this.element.addEventListener("mouseleave", this.boundHide);
      this.element.addEventListener("focusin", this.boundShow);
      this.element.addEventListener("focusout", this.boundHide);
    } else {
      this.element.addEventListener("click", this.toggle);
    }

    // The sidebar expands on hover/focus and collapses when the cursor
    // leaves. Once collapsed, the popover would be pointing at where the
    // button used to be — so dismiss it.
    this.sidebar = this.element.closest(".sidebar");
    this.boundOnSidebarLeave = () => this.hide();
    this.sidebar?.addEventListener("mouseleave", this.boundOnSidebarLeave);

    // The pin button toggles the sidebar's pinned state. If the user pins
    // or unpins while the popover is open, our positioning is off — close.
    this.pinButton = this.sidebar?.querySelector(".sidebar__pin-button");
    this.pinButton?.addEventListener("click", this.boundOnSidebarLeave);
  }

  disconnect() {
    if (this.hoverCapable) {
      this.element.removeEventListener("mouseenter", this.boundShow);
      this.element.removeEventListener("mouseleave", this.boundHide);
      this.element.removeEventListener("focusin", this.boundShow);
      this.element.removeEventListener("focusout", this.boundHide);
    } else {
      this.element.removeEventListener("click", this.toggle);
    }
    this.sidebar?.removeEventListener("mouseleave", this.boundOnSidebarLeave);
    this.pinButton?.removeEventListener("click", this.boundOnSidebarLeave);
    this.hide();
  }

  toggle = (event) => {
    event.preventDefault();
    event.stopPropagation();
    if (this.popover) {
      this.hide();
    } else {
      this.show();
    }
  };

  show() {
    if (this.popover) return;

    this.popover = document.createElement("div");
    this.popover.className = "locked-tab-popover";
    this.popover.setAttribute("role", "tooltip");
    this.popover.textContent = this.messageValue;
    document.body.appendChild(this.popover);

    this.reposition();

    requestAnimationFrame(() => {
      if (this.popover)
        this.popover.classList.add("locked-tab-popover--visible");
    });

    setTimeout(() => {
      document.addEventListener("click", this.boundOutsideClick);
      document.addEventListener("keydown", this.boundKey);
      window.addEventListener("scroll", this.boundReposition, {
        passive: true,
      });
      window.addEventListener("resize", this.boundReposition, {
        passive: true,
      });
    }, 0);
  }

  hide() {
    document.removeEventListener("click", this.boundOutsideClick);
    document.removeEventListener("keydown", this.boundKey);
    window.removeEventListener("scroll", this.boundReposition);
    window.removeEventListener("resize", this.boundReposition);

    if (this.popover) {
      this.popover.remove();
      this.popover = null;
    }
  }

  reposition() {
    if (!this.popover) return;
    const rect = this.element.getBoundingClientRect();
    const popoverRect = this.popover.getBoundingClientRect();
    const gap = 12;
    const top = rect.top + rect.height / 2 - popoverRect.height / 2;
    const left = rect.right + gap;
    this.popover.style.top = `${Math.max(8, top)}px`;
    this.popover.style.left = `${left}px`;
  }

  handleOutsideClick(event) {
    if (this.element.contains(event.target)) return;
    if (this.popover && this.popover.contains(event.target)) return;
    this.hide();
  }

  handleKey(event) {
    if (event.key === "Escape") this.hide();
  }
}
