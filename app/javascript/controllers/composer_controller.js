import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dropZone", "grid", "fileInput", "info", "timeLabel"];
  static values = {
    maxFiles: { type: Number, default: 4 },
    previewTimeUrl: String,
  };

  #files = [];
  #urls = [];
  #timeFetched = false;

  connect() {
    this.#acceptedTypes = this.fileInputTarget.accept
      .split(",")
      .map((t) => t.trim());
  }

  disconnect() {
    this.#revokeUrls();
  }

  showInfo() {
    if (!this.hasInfoTarget) return;
    this.infoTarget.hidden = false;
    if (
      this.hasTimeLabelTarget &&
      this.hasPreviewTimeUrlValue &&
      !this.#timeFetched
    ) {
      this.#timeFetched = true;
      fetch(this.previewTimeUrlValue, {
        headers: { Accept: "application/json" },
      })
        .then((r) => r.json())
        .then(({ preview_time }) => {
          this.timeLabelTarget.textContent = preview_time
            ? `${preview_time} will be logged`
            : "Could not load coding time";
        })
        .catch(() => {
          this.timeLabelTarget.textContent = "Could not load coding time";
        });
    }
  }

  selectFiles() {
    this.#addFiles(this.fileInputTarget.files);
  }

  drop(event) {
    event.preventDefault();
    this.dropZoneTarget.classList.remove("feed-composer__main--dragover");
    this.#addFiles(event.dataTransfer.files);
  }

  dragover(event) {
    event.preventDefault();
    this.dropZoneTarget.classList.add("feed-composer__main--dragover");
  }

  dragleave() {
    this.dropZoneTarget.classList.remove("feed-composer__main--dragover");
  }

  paste(event) {
    const files = Array.from(event.clipboardData?.files || []);
    if (files.length === 0) return;
    event.preventDefault();
    this.#addFiles(files);
  }

  removeFile({ params: { index } }) {
    this.#files.splice(index, 1);
    this.#render();
  }

  // private

  #acceptedTypes = [];

  #addFiles(fileList) {
    const incoming = Array.from(fileList).filter((f) =>
      this.#acceptedTypes.includes(f.type),
    );
    const room = this.maxFilesValue - this.#files.length;
    this.#files.push(...incoming.slice(0, Math.max(0, room)));
    this.#render();
  }

  #render() {
    this.#revokeUrls();
    this.gridTarget.innerHTML = "";

    if (this.#files.length === 0) {
      this.gridTarget.hidden = true;
      this.gridTarget.dataset.count = "0";
      this.#syncInput();
      return;
    }

    this.gridTarget.hidden = false;
    this.gridTarget.dataset.count = String(this.#files.length);

    this.#files.forEach((file, i) => {
      const wrap = document.createElement("div");
      wrap.className = "feed-composer__preview";

      if (file.type.startsWith("image/")) {
        const url = URL.createObjectURL(file);
        this.#urls.push(url);
        const img = document.createElement("img");
        img.src = url;
        img.alt = file.name;
        img.className = "feed-composer__preview-image";
        wrap.appendChild(img);
      } else {
        const vid = document.createElement("video");
        vid.src = URL.createObjectURL(file);
        this.#urls.push(vid.src);
        vid.preload = "metadata";
        vid.muted = true;
        vid.className = "feed-composer__preview-video";
        vid.addEventListener(
          "loadeddata",
          () => {
            vid.currentTime = 0.1;
          },
          { once: true },
        );
        wrap.appendChild(vid);
      }

      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "feed-composer__preview-remove";
      btn.setAttribute("aria-label", "Remove attachment");
      btn.dataset.action = "composer#removeFile";
      btn.dataset.composerIndexParam = String(i);
      btn.innerHTML = `<svg aria-hidden="true" viewBox="0 0 320.591 320.591" xmlns="http://www.w3.org/2000/svg"><path d="m30.391 318.583c-7.86.457-15.59-2.156-21.56-7.288-11.774-11.844-11.774-30.973 0-42.817l257.812-257.813c12.246-11.459 31.462-10.822 42.921 1.424 10.362 11.074 10.966 28.095 1.414 39.875l-259.331 259.331c-5.893 5.058-13.499 7.666-21.256 7.288z"/><path d="m287.9 318.583c-7.966-.034-15.601-3.196-21.257-8.806l-257.813-257.814c-10.908-12.738-9.425-31.908 3.313-42.817 11.369-9.736 28.136-9.736 39.504 0l259.331 257.813c12.243 11.462 12.876 30.679 1.414 42.922-.456.487-.927.958-1.414 1.414-6.35 5.522-14.707 8.161-23.078 7.288z"/></svg>`;
      wrap.appendChild(btn);

      this.gridTarget.appendChild(wrap);
    });

    this.#syncInput();
  }

  #syncInput() {
    const dt = new DataTransfer();
    this.#files.forEach((f) => dt.items.add(f));
    this.fileInputTarget.files = dt.files;
  }

  #revokeUrls() {
    this.#urls.forEach((u) => URL.revokeObjectURL(u));
    this.#urls = [];
  }
}
