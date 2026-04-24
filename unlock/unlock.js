(function () {
  "use strict";

  const WAYBACK_API = "https://archive.org/wayback/available?url=";
  const ARCHIVE_IS_NEWEST = "https://archive.ph/newest/";

  const chooser = document.getElementById("chooser");
  const loading = document.getElementById("loading");
  const loadingStatus = document.getElementById("loadingStatus");
  const reader = document.getElementById("reader");
  const form = document.getElementById("urlform");
  const input = document.getElementById("urlinput");
  const results = document.getElementById("results");

  const params = new URLSearchParams(location.search);
  const incoming = params.get("url");

  if (incoming) {
    startReaderFlow(incoming);
  } else {
    showChooser();
  }

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const value = input.value.trim();
    if (!value) return;
    startReaderFlow(value);
  });

  async function startReaderFlow(rawURL) {
    const url = normalizeURL(rawURL);
    if (!url) {
      showChooser({ error: "Ongeldige URL: " + rawURL });
      return;
    }

    if (isArchiveHost(url)) {
      // De gedeelde URL is al een archief-link. Niets te ontgrendelen, stuur
      // rechtstreeks door.
      window.location.replace(url);
      return;
    }

    showLoading("Zoeken in Wayback Machine…");

    let snapshot = null;
    let lookupError = null;
    try {
      snapshot = await waybackLookup(url);
    } catch (err) {
      lookupError = err && err.message ? err.message : String(err);
    }

    if (!snapshot) {
      showChooser({
        originalURL: url,
        note: lookupError
          ? "Wayback-lookup faalde: " + lookupError
          : "Geen Wayback-snapshot gevonden.",
        links: chooserLinks(url, null)
      });
      return;
    }

    showLoading("Snapshot downloaden…");

    let article = null;
    let extractError = null;
    try {
      article = await extractArticle(snapshot, url);
    } catch (err) {
      extractError = err && err.message ? err.message : String(err);
    }

    if (article && article.content && article.textContent && article.textContent.length > 200) {
      renderReader(article, url, snapshot);
      return;
    }

    showChooser({
      originalURL: url,
      note: extractError
        ? "Reader-extractie mislukt: " + extractError
        : "Reader-extractie leverde geen tekst op. Open het snapshot zelf.",
      links: chooserLinks(url, snapshot)
    });
  }

  async function waybackLookup(url) {
    const response = await fetchWithTimeout(WAYBACK_API + encodeURIComponent(url), 10000);
    if (!response.ok) throw new Error("availability HTTP " + response.status);
    const data = await response.json();
    const closest = data && data.archived_snapshots && data.archived_snapshots.closest;
    if (closest && closest.available && closest.status === "200" && closest.url) {
      return closest.url.replace(/^http:/, "https:");
    }
    return null;
  }

  async function extractArticle(snapshotURL, originalURL) {
    const rawURL = snapshotURL.replace(/\/web\/(\d+)\//, "/web/$1id_/");
    const response = await fetchWithTimeout(rawURL, 15000);
    if (!response.ok) throw new Error("snapshot HTTP " + response.status);

    showLoading("Artikel parsen…");
    const html = await response.text();

    const doc = new DOMParser().parseFromString(html, "text/html");
    if (!doc || !doc.body) throw new Error("geen geldige HTML in snapshot");

    // Forceer base-href zodat Readability absolute URLs genereert voor
    // afbeeldingen en links.
    const base = doc.createElement("base");
    base.href = originalURL;
    if (doc.head) doc.head.prepend(base);

    // Strip Wayback-wrapper elementen die soms in id_-responses blijven hangen.
    doc.querySelectorAll("#wm-ipp, #wm-ipp-base, #donato, [id^='wm-']").forEach((n) => n.remove());

    showLoading("Reader extraheren…");
    // Geef Safari een beurt om de loading-status te renderen voordat we een
    // CPU-intensieve Readability-pass doen.
    await new Promise((resolve) => setTimeout(resolve, 0));

    return new Readability(doc).parse();
  }

  async function fetchWithTimeout(url, ms) {
    const signal = createTimeoutSignal(ms);
    try {
      return await fetch(url, {
        signal,
        credentials: "omit",
        redirect: "follow",
        cache: "no-store"
      });
    } catch (err) {
      if (err && (err.name === "AbortError" || err.name === "TimeoutError")) {
        throw new Error("timeout na " + (ms / 1000) + "s");
      }
      throw err;
    }
  }

  function createTimeoutSignal(ms) {
    if (typeof AbortSignal !== "undefined" && typeof AbortSignal.timeout === "function") {
      return AbortSignal.timeout(ms);
    }
    const ctrl = new AbortController();
    setTimeout(() => ctrl.abort(), ms);
    return ctrl.signal;
  }

  function renderReader(article, originalURL, snapshotURL) {
    document.title = article.title ? article.title + " — SuperReader" : "SuperReader";

    document.getElementById("readerTitle").textContent = article.title || "Zonder titel";

    const metaBits = [];
    if (article.byline) metaBits.push(article.byline);
    if (article.siteName) metaBits.push(article.siteName);
    if (article.publishedTime) {
      const date = new Date(article.publishedTime);
      if (!isNaN(date.getTime())) metaBits.push(date.toLocaleDateString("nl-NL"));
    }
    document.getElementById("readerMeta").textContent = metaBits.join(" · ");

    const content = document.getElementById("readerContent");
    content.innerHTML = article.content || "";

    // Absolutiseer relatieve afbeeldingen (zou door base-href gedekt moeten
    // zijn maar sommige srcset-vormen ontsnappen).
    content.querySelectorAll("img").forEach((img) => {
      if (img.getAttribute("src") && img.src.startsWith(location.origin)) {
        try {
          const abs = new URL(img.getAttribute("src"), originalURL);
          img.src = abs.toString();
        } catch (_) { /* no-op */ }
      }
      img.setAttribute("loading", "lazy");
      img.setAttribute("referrerpolicy", "no-referrer");
    });

    document.getElementById("linkOriginal").href = originalURL;
    document.getElementById("linkSnapshot").href = snapshotURL;

    show(reader);
    window.scrollTo(0, 0);
  }

  function showChooser(options) {
    options = options || {};
    if (options.originalURL) input.value = options.originalURL;

    results.innerHTML = "";
    if (options.note) {
      const li = document.createElement("li");
      li.className = "note";
      li.textContent = options.note;
      results.appendChild(li);
    }
    const links = options.links || chooserLinks(options.originalURL || "", null);
    for (const entry of links) {
      const a = document.createElement("a");
      a.className = "result " + (entry.state || "");
      a.href = entry.href;
      a.target = "_blank";
      a.rel = "noopener";
      a.innerHTML =
        '<span class="icon">→</span>' +
        '<span class="body"><span class="title"></span><span class="status"></span></span>';
      a.querySelector(".title").textContent = entry.title;
      a.querySelector(".status").textContent = entry.status;
      results.appendChild(a);
    }
    if (options.error) {
      const li = document.createElement("li");
      li.className = "note error";
      li.textContent = options.error;
      results.appendChild(li);
    }
    show(chooser);
  }

  function chooserLinks(url, snapshot) {
    const entries = [];
    if (snapshot) {
      entries.push({ title: "Wayback snapshot", status: "Volledige pagina-weergave", href: snapshot });
    }
    if (url) {
      entries.push({ title: "archive.is", status: "Nieuwste snapshot proberen", href: ARCHIVE_IS_NEWEST + url });
      entries.push({ title: "Origineel", status: "Open in browser", href: url });
    }
    return entries;
  }

  function showLoading(text) {
    loadingStatus.textContent = text;
    show(loading);
  }

  function show(section) {
    for (const node of [chooser, loading, reader]) {
      node.hidden = node !== section;
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
})();
