(function () {
  "use strict";

  const WAYBACK_API = "https://archive.org/wayback/available?url=";
  const ARCHIVE_IS = "https://archive.ph/newest/";

  const form = document.getElementById("urlform");
  const input = document.getElementById("urlinput");
  const results = document.getElementById("results");

  const params = new URLSearchParams(location.search);
  const incoming = params.get("url");
  const auto = params.get("auto") === "1";

  if (incoming) {
    input.value = incoming;
    run(incoming, auto);
  }

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const value = input.value.trim();
    if (!value) return;
    run(value, false);
  });

  async function run(rawURL, autoRedirect) {
    const url = normalizeURL(rawURL);
    if (!url) {
      render([{ title: "Ongeldige URL", status: rawURL, state: "err" }]);
      return;
    }

    if (isArchiveHost(url)) {
      window.location.replace(url);
      return;
    }

    const entries = [
      { id: "wayback", title: "Wayback Machine", status: "Zoeken…", state: "pending" },
      { id: "archive", title: "archive.is", status: "Klik om snapshot te openen", state: "ready", href: ARCHIVE_IS + url },
      { id: "original", title: "Origineel", status: "Open in Safari (reader-mode)", state: "ready", href: url }
    ];
    render(entries);

    let snapshot = null;
    try {
      snapshot = await waybackLookup(url);
    } catch (err) {
      // swallowed — we just show the fallback options
    }

    if (snapshot) {
      entries[0] = {
        id: "wayback",
        title: "Wayback Machine",
        status: "Snapshot gevonden — openen",
        state: "ok",
        href: snapshot
      };
      render(entries);

      if (autoRedirect) {
        window.location.replace(snapshot);
        return;
      }
    } else {
      entries[0] = {
        id: "wayback",
        title: "Wayback Machine",
        status: "Geen snapshot",
        state: "err"
      };
      render(entries);

      if (autoRedirect) {
        // Geen Wayback snapshot — stuur door naar archive.is/newest zodat de
        // gebruiker meteen een poging ziet in plaats van onze tussenpagina.
        window.location.replace(ARCHIVE_IS + url);
      }
    }
  }

  function normalizeURL(value) {
    try {
      const parsed = new URL(value);
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return null;
      return parsed.toString();
    } catch (_) {
      return null;
    }
  }

  function isArchiveHost(url) {
    try {
      const host = new URL(url).hostname.toLowerCase();
      return (
        host === "archive.is" ||
        host === "archive.ph" ||
        host === "archive.today" ||
        host === "web.archive.org" ||
        host.endsWith(".archive.is") ||
        host.endsWith(".archive.ph")
      );
    } catch (_) {
      return false;
    }
  }

  async function waybackLookup(url) {
    const response = await fetch(WAYBACK_API + encodeURIComponent(url), {
      headers: { Accept: "application/json" }
    });
    if (!response.ok) return null;
    const data = await response.json();
    const closest = data && data.archived_snapshots && data.archived_snapshots.closest;
    if (closest && closest.available && closest.status === "200" && closest.url) {
      return closest.url.replace(/^http:/, "https:");
    }
    return null;
  }

  function render(entries) {
    results.innerHTML = "";
    for (const entry of entries) {
      const tag = entry.href ? "a" : "li";
      const node = document.createElement(tag);
      node.className = "result " + (entry.state || "");
      if (entry.href) {
        node.href = entry.href;
        node.target = "_blank";
        node.rel = "noopener";
      }
      node.innerHTML =
        '<span class="icon">' + iconFor(entry.state) + "</span>" +
        '<span class="body">' +
          '<span class="title"></span>' +
          '<span class="status"></span>' +
        "</span>";
      node.querySelector(".title").textContent = entry.title;
      node.querySelector(".status").textContent = entry.status;
      results.appendChild(node);
    }
  }

  function iconFor(state) {
    switch (state) {
      case "pending": return '<span class="spinner" aria-hidden="true"></span>';
      case "ok": return "✓";
      case "err": return "✕";
      default: return "→";
    }
  }
})();
