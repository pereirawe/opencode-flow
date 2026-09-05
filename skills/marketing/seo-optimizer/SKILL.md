---
name: SEO Optimizer
description: Search Engine Optimization specialist for content strategy, technical SEO, keyword research, ranking improvements, and social sharing previews. Use when optimizing website content, improving search rankings, conducting keyword analysis, implementing SEO best practices, auditing or fixing Open Graph / social sharing meta (og:image, og:description, Twitter Cards, image_src), making link previews work on Facebook, WhatsApp, LinkedIn, Twitter/X, or designing og:image cards. Expert in on-page SEO, meta tags, schema markup, and Core Web Vitals.
---

# SEO Optimizer

Comprehensive guidance for search engine optimization across content, technical implementation, and strategic planning to improve organic search visibility and rankings.

## When to Use This Skill

Use this skill when:
- Optimizing website content for search engines
- Conducting keyword research and analysis
- Implementing technical SEO improvements
- Creating SEO-friendly meta tags and descriptions
- Auditing websites for SEO issues
- Improving Core Web Vitals and page speed
- Implementing schema markup (structured data)
- Planning content strategy for organic traffic

## SEO Fundamentals

### 1. Keyword Research & Strategy

**Primary Keyword Selection:**
- Focus on search intent (informational, navigational, transactional, commercial)
- Balance search volume with competition
- Consider keyword difficulty and ranking potential
- Target long-tail keywords for quick wins

**Keyword Research Process:**
```
1. Identify seed keywords from business objectives
2. Use tools to expand keyword list (Google Keyword Planner, Ahrefs, SEMrush)
3. Analyze search volume and difficulty
4. Group keywords by topic clusters
5. Map keywords to content types and pages
6. Prioritize based on potential ROI
```

**Content Optimization Formula:**
- Primary keyword: 1-2% density (natural placement)
- Include in: Title tag, H1, first paragraph, URL, meta description
- Use semantic variations and related terms
- Maintain natural readability (don't keyword stuff)

### 2. On-Page SEO

**Title Tag Optimization:**
```html
<!-- Good: Descriptive, includes keyword, under 60 characters -->
<title>Ultimate Guide to React Hooks - Learn useEffect & useState</title>

<!-- Bad: Too long, keyword stuffing, generic -->
<title>React Hooks Guide React Hooks Tutorial React Hooks Examples Learn React</title>
```

**Best Practices:**
- Keep under 60 characters (displayed in SERPs)
- Place primary keyword near the beginning
- Include brand name if space permits
- Make compelling and click-worthy
- Unique for every page

**Meta Description:**
```html
<!-- Good: Compelling, includes keywords, call-to-action, 150-160 chars -->
<meta name="description" content="Master React Hooks with our comprehensive guide. Learn useState, useEffect, and custom hooks with practical examples. Start building better React apps today.">

<!-- Bad: Too short, no value proposition -->
<meta name="description" content="React Hooks guide and tutorial">
```

**Header Structure:**
```html
<!-- Proper hierarchy -->
<h1>Main Page Title (Primary Keyword)</h1>
  <h2>Section Heading (Related Keywords)</h2>
    <h3>Subsection</h3>
    <h3>Subsection</h3>
  <h2>Another Section</h2>
    <h3>Subsection</h3>
```

**URL Structure:**
```
✅ Good URLs:
- /blog/react-hooks-guide
- /products/running-shoes
- /learn/javascript-async-await

❌ Bad URLs:
- /blog?p=12345
- /products/cat-1/subcat-2/item-999
- /page.php?id=abc&ref=xyz
```

**Image Optimization:**
```html
<!-- Optimized image -->
<img
  src="/images/react-hooks-diagram-800w.webp"
  alt="React Hooks lifecycle diagram showing useState and useEffect"
  width="800"
  height="600"
  loading="lazy"
/>
```

**Best Practices:**
- Use descriptive, keyword-rich alt text
- Compress images (WebP format preferred)
- Specify dimensions to prevent layout shift
- Use lazy loading for below-fold images
- Include captions when relevant

### 3. Content Quality

**E-E-A-T Principles (Experience, Expertise, Authoritativeness, Trust):**
- Demonstrate author expertise with credentials
- Cite authoritative sources
- Keep content accurate and up-to-date
- Show real experience and original insights
- Include author bios and bylines

**Content Structure for SEO:**
```markdown
# Main Title (H1) - Primary Keyword

Brief introduction with primary keyword in first 100 words.

## What is [Topic]? (H2) - Answer core question

Comprehensive explanation with examples.

## Why [Topic] Matters (H2) - Value proposition

Benefits and use cases.

## How to [Action] (H2) - Practical guide

Step-by-step instructions with visuals.

## Best Practices (H2) - Advanced tips

Expert recommendations.

## Common Mistakes to Avoid (H2)

Troubleshooting and pitfalls.

## Conclusion

Summary and call-to-action.
```

**Content Length Guidelines:**
- Blog posts: 1,500-2,500 words (comprehensive topics)
- Product pages: 300-500 words minimum
- Category pages: 500-1,000 words
- Homepage: 500+ words

### 4. Technical SEO

**Schema Markup (Structured Data):**
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Complete Guide to React Hooks",
  "image": "https://example.com/images/react-hooks.jpg",
  "datePublished": "2024-01-15",
  "dateModified": "2024-02-01",
  "author": {
    "@type": "Person",
    "name": "Jane Developer"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Tech Academy",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  }
}
```

**Common Schema Types:**
- Article (blog posts)
- Product (e-commerce)
- FAQ (question/answer pages)
- HowTo (tutorials and guides)
- Organization (company info)
- LocalBusiness (location-based businesses)
- BreadcrumbList (navigation paths)
- Review/AggregateRating (ratings and reviews)

**Robots.txt Configuration:**
```
User-agent: *
Disallow: /admin/
Disallow: /private/
Disallow: /api/
Allow: /api/public/

Sitemap: https://example.com/sitemap.xml
```

**XML Sitemap Structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-15</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/blog/react-hooks-guide</loc>
    <lastmod>2024-01-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

**Canonical Tags:**
```html
<!-- Prevent duplicate content issues -->
<link rel="canonical" href="https://example.com/original-page">

<!-- Handle URL parameters -->
<link rel="canonical" href="https://example.com/products/shoes">
<!-- Even if accessed via: /products/shoes?color=red&size=10 -->
```

### 5. Core Web Vitals

**Largest Contentful Paint (LCP) - Target: < 2.5s**
- Optimize images and videos
- Use CDN for static assets
- Minimize render-blocking resources
- Implement lazy loading

**First Input Delay (FID) - Target: < 100ms**
- Minimize JavaScript execution time
- Break up long tasks
- Use web workers for heavy computations
- Defer non-critical JavaScript

**Cumulative Layout Shift (CLS) - Target: < 0.1**
- Set size attributes on images and videos
- Avoid inserting content above existing content
- Use transform animations instead of layout-triggering properties
- Reserve space for ads and embeds

**Page Speed Optimization:**
```html
<!-- Preload critical resources -->
<link rel="preload" href="/fonts/main.woff2" as="font" crossorigin>

<!-- Defer non-critical CSS -->
<link rel="preload" href="/styles/non-critical.css" as="style" onload="this.onload=null;this.rel='stylesheet'">

<!-- Async/defer JavaScript -->
<script src="/js/analytics.js" async></script>
<script src="/js/main.js" defer></script>
```

### 6. Mobile SEO

**Mobile-First Optimization:**
- Responsive design (mobile-friendly test passed)
- Touch-friendly buttons (minimum 48x48px)
- Readable font sizes (16px minimum)
- Proper viewport configuration
- Fast mobile page speed

**Viewport Configuration:**
```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

### 7. Internal Linking Strategy

**Best Practices:**
- Use descriptive anchor text (avoid "click here")
- Link to relevant, contextual pages
- Maintain logical hierarchy and flow
- Include 3-5 internal links per 1,000 words
- Update old content with links to new content

**Example:**
```markdown
Learn more about [advanced React patterns](/guides/react-patterns)
or check out our [useState hook tutorial](/tutorials/usestate-guide).
```

## Social Sharing & Open Graph (og:image compatibility)

The Open Graph tags are what Facebook, WhatsApp, LinkedIn, Telegram and
Twitter/X read when a link is pasted. A site can rank perfectly and still show
a broken/empty link preview if these are wrong. Treat them as a first-class,
explicit contract.

### Head meta blueprint (all sharing platforms)

```html
<!-- Primary SEO -->
<title>Brand — Compelling keyword phrase (≤ 60 chars)</title>
<meta name="description" content="150–160 chars, compelling, CTA." />
<link rel="canonical" href="https://example.com/" />
<meta name="robots" content="index, follow" />
<meta name="viewport" content="width=device-width, initial-scale=1" />

<!-- Open Graph -->
<meta property="og:site_name" content="Brand" />
<meta property="og:type" content="website" />
<meta property="og:title" content="Brand — Compelling headline (≤ 60 chars)" />
<meta property="og:description" content="Self-contained, informative; ~80–200 chars (platforms truncate at different lengths)." />
<meta property="og:url" content="https://example.com/" />   <!-- ALWAYS absolute + canonical -->
<meta property="og:locale" content="en_US" />
<meta property="og:image" content="https://example.com/og-image.jpeg" />          <!-- ALWAYS absolute -->
<meta property="og:image:secure_url" content="https://example.com/og-image.jpeg" />
<meta property="og:image:type" content="image/jpeg" />
<meta property="og:image:width" content="1200" />            <!-- MUST equal real pixels -->
<meta property="og:image:height" content="630" />
<meta property="og:image:alt" content="Descriptive alt of the card content." />

<!-- Legacy <link rel="image_src"> (kept for compatibility; NOT read by WhatsApp,
     which uses the Facebook crawler and og: tags) -->
<link rel="image_src" href="https://example.com/og-image.jpeg" />

<!-- Twitter / X -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="…same as og:title…" />
<meta name="twitter:description" content="…same as og:description…" />
<meta name="twitter:image" content="https://example.com/og-image.jpeg" />         <!-- absolute -->

<!-- Structured data (see Technical SEO) -->
<script type="application/ld+json">
  { "@context": "https://schema.org", "@type": "Organization",
    "name": "Brand", "url": "https://example.com/",
    "logo": "https://example.com/og-image.jpeg" }
</script>
```

### og:image hard rules (learned from production failures)

- **URL must be absolute** (`https://host/path.jpg`). Facebook's Sharing
  Debugger rejects relative values (`/og-image.jpg`) with *"The property
  'og:image' of the URL '…' provided is not valid"*. Never ship a relative
  og:image/twitter:image/image_src.
- **`og:image:width`/`height` are optional** (Meta documents them as such — the
  crawler can render without them). When declared they MUST equal the real
  pixel dimensions; a wrong value makes scrapers re-download/mis-render.
- Add `og:image:type` (`image/jpeg`/`image/png` — the only formats reliably
  supported by social scrapers; WebP is not) and `og:image:secure_url` when the
  site is served over HTTPS.
- The image file must be publicly reachable: HTTP 200, correct `Content-Type`,
  served over HTTPS, not blocked by `robots.txt` or a login wall. Keep the file
  small (target < ~300 KB, well below 5 MB) — Meta publishes no hard ceiling,
  but X documents a 5 MB limit for `twitter:image`; oversized files fail or get
  downscaled on several platforms.
- Keep the file extension consistent with the real encoding (a `.jpeg` that is
  actually a PNG fails).
- Reference the same absolute file in JSON-LD (`logo`/`image`) so all systems
  agree.

### og:image asset spec (1200×630, 1.91:1)

- Canvas exactly **1200×630**, JPG sRGB (PNG master kept alongside for reuse).
- **No baked-in rounded corners** — platforms clip corners themselves; only
  imagery may sit at the edges.
- **Safe zones**: keep every critical element (logo, headline, ticker) within
  ~90 px of the left/right and ~60 px of the top/bottom. Nothing essential in
  the right ~200 px or bottom ~40 px (WhatsApp/LinkedIn crop/truncate there).
- Readable at preview scale: LinkedIn renders ~400 px wide, WhatsApp ~280 px.
  Headline ≥ 15:1 contrast on dark; small text ≥ 6:1 (WCAG AA).
- Target < 300 KB; avoid heavy full-width gradients (JPG banding) — use a flat
  base + subtle radial glows.
- Regenerate whenever the design/identity changes.

### Copy length (descriptions)

- `og:description` and `twitter:description`: self-contained and informative.
  Platforms truncate at different lengths (LinkedIn shows ~100 chars when it
  falls back to `meta name="description"`, Facebook ~200) — there is no
  official minimum, so put the key information in the first ~80–200 chars.
- `name="description"`: classic SEO 150–160 chars.
- `og:title`/`title`: ≤ 60 chars, keyword + brand.

### Validation & cache-refresh workflow

| Platform | Validator | Refresh tool |
|---|---|---|
| Facebook / WhatsApp | developers.facebook.com/tools/debug | "Scrape Again" (same Meta crawler also feeds WhatsApp) |
| LinkedIn | linkedin.com/post-inspector | "Inspect" |
| Twitter/X | no public validator (X retired cards.twitter.com/validator) | paste URL in the X composer to preview; or check via opengraph.xyz / metatags.io |

- WhatsApp has **no official cache-clear**. Previews are cached per exact URL:
  share `https://host/?v=2` (any new query param) to force a fresh scrape, and
  avoid sharing URLs with `#fragment`s when testing.
- After any meta/og change, re-run the validators — old previews persist until
  recrawled.

### Common failure matrix

| Symptom | Likely cause | Fix |
|---|---|---|
| "URL no válida" on og:image | Relative `og:image` URL | Use absolute URL |
| Preview shows old image | Platform cache | Re-scrape / `?v=2` cache-buster |
| Image not shown at all | og:image missing/inaccessible/too big | Absolute URL, 200 + correct content-type, < 5 MB |
| LinkedIn "og:description too short" | og:description missing/weak | Write ~80–200 self-contained chars (LinkedIn truncates; no official min) |
| Distorted/cropped preview | width/height mismatch | Set tags to real pixel size |
| Wrong mime/extension | file format ≠ extension | Export/rename correctly (JPEG data in .jpg/.jpeg) |
| No preview in any chat | page served only JS-rendered | Put meta in server HTML, not client JS |

## AI Crawlers, llms.txt, robots.txt & Sitemaps (modern SEO)

Search is no longer only Google: LLMs and AI assistants (ChatGPT, Perplexity,
Claude, Gemini, Bing Copilot) ingest the site directly. Treat **crawlability by
AI agents**, an **llms.txt map**, a **lean robots.txt policy** and a **clean
sitemap** as first-class deliverables.

### 1. robots.txt & AI crawler policy

| User-agent | What it does | Typical stance |
|---|---|---|
| `Googlebot` / `Bingbot` | Classic search | Allow |
| `GPTBot` | OpenAI web crawling + training | Allow (search/training) or disallow |
| `OAI-SearchBot` | OpenAI/ChatGPT search results | Allow (visibility) |
| `ClaudeBot`, `Claude-User`, `Claude-SearchBot` | Anthropic | Allow search (`Claude-SearchBot`/`Claude-User`); disallow `ClaudeBot` to opt out of training |
| `PerplexityBot` | Perplexity | Allow (visibility) |
| `Google-Extended` | Google AI training/tuning opt-out | Disallow to opt out of training |
| `Applebot-Extended` | Apple AI | Disallow to opt out |
| `CCBot` (Common Crawl), `Amazonbot`, `bytespider`, `Meta-ExternalAgent`, `omgili` | Bulk/third-party crawlers | Usually disallow (noisy) |

Rules:
- robots.txt only needs to list agents you **diverge** on; `User-agent: *`
  covers the rest. Matching is by **specificity, not order** (RFC 9309): each
  crawler uses the group whose user-agent most specifically identifies it — a
  `Googlebot` group beats `*` regardless of position. Within a group, the rule
  with the longest-matching path wins (`Allow` wins ties). Listing specific
  agents before the catch-all is a readability convention, not what decides
  the winner.
- Decide deliberately: allow search-oriented agents (`OAI-SearchBot`,
  `Claude-SearchBot`, `PerplexityBot`) to stay visible in AI answers; block
  only the training/aggregator crawlers you do not want, e.g. `CCBot`,
  `Amazonbot`, `GPTBot` (optional), `Google-Extended`, `Applebot-Extended`.
- **Never block** assets the og/social scraper needs: keep
  `facebookexternalhit`/`Twitterbot`/`LinkedInbot` allowed and make sure
  `og-image` files aren't under a `Disallow`.
- Keep `/llms.txt` allowed for every agent.
- `Sitemap:` line must be an absolute URL and live at the bottom of the file.

```txt
# Search engines + AI search assistants: allowed
User-agent: Googlebot
Allow: /

User-agent: Bingbot
Allow: /

User-agent: OAI-SearchBot
Allow: /

User-agent: Claude-SearchBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: facebookexternalhit
Allow: /

User-agent: Twitterbot
Allow: /

# Training / aggregator crawlers: explicitly blocked
User-agent: CCBot
Disallow: /

User-agent: Amazonbot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: Applebot-Extended
Disallow: /

# Everything else (incl. GPTBot, ClaudeBot): allowed to crawl pages but kept
# out of parameterized URLs
User-agent: *
Allow: /llms.txt
Disallow: /*?*

# Sitemap
Sitemap: https://example.com/sitemap.xml
```

Caveat: robots.txt is advisory, not enforced by all bots; keep sensitive pages
behind auth, not just robots.

### 2. llms.txt (llmstxt.org standard)

A plain-text, high-signal map of the site that LLMs read first. Serve it at
`/llms.txt` (`text/plain`). Format:

```text
# Brand Name

> One-line positioning.

2–4 short paragraphs of factual, verifiable summary (people, offer, proof,
geo/scope). Keep it tight — the model reads this before visiting pages.

## Services
- [Service one](https://example.com/services/one)
- [Service two](https://example.com/services/two)

## Industries
- [Industry A](https://example.com/industries/a)

## Optional
- [Full documentation](https://example.com/docs)
```

Guidelines:
- H1 (`#`) = brand; `##` = sections; one level deep is enough.
- `##` sections hold **link lists** (`[name](url)`) to canonical pages. Contact
  details, address or email belong in the intro summary paragraphs (plain text,
  no heading), not as bare text under a heading.
- Bullet links to the **most useful canonical pages first**, with descriptive
  anchor text. No `#fragment` links, no tracking params, absolute HTTPS URLs.
- Prefer concise factual statements over marketing puffery (models cite them).
- The conventional secondary-information block is named **`## Optional`** (spec
  v2); a separate `llms-full.txt` can hold long documentation.
- Caveat: per Google's own guidance (2026) llms.txt does **not** affect Google
  Search ranking/visibility — it serves third-party AI assistants/agents. Do
  not overpromise it as an SEO lever.
- Keep it in sync with real content; re-export after redesigns (same care as
  og:image).

### 3. Sitemaps

- Include only canonical, `200` pages. **Never** list URLs with
  `#fragments`/anchors (share links like `/#top` do not belong in a sitemap)
  or pure parameter variants.
- Absolute `https` URLs; `<lastmod>` as ISO 8601 (`2026-08-12` or full
  `T`-timestamp) and update it whenever the page changes.
- `<changefreq>`/`<priority>` are informational for Google — optional.
- Limits: ≤ 50,000 URLs and ≤ 50 MB per file; use a sitemap index beyond that.
- Reference it in `robots.txt` (absolute) and submit it in Google Search
  Console + Bing Webmaster Tools.
- Multilingual: use `<xhtml:link rel="alternate" hreflang="…">` inside each
  `<url>` (and/or `hreflang` link tags in the page `<head>`), always paired
  with a matching `hreflang="x-default"`.

```xml
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-08-12</lastmod>
    <xhtml:link rel="alternate" hreflang="en" href="https://example.com/" />
    <xhtml:link rel="alternate" hreflang="es" href="https://example.com/es/" />
    <xhtml:link rel="alternate" hreflang="x-default" href="https://example.com/" />
  </url>
</urlset>
```

### 4. AI search / GEO visibility trends

- Serve content in **static/server-rendered HTML**; many AI crawlers do not run
  JS. Meta/OG that only exists after hydration is invisible to them.
- Put the primary topic and a direct answer in the first ~100 words; use clean
  `h1 → h2/h3` hierarchy; answer Q&A-shaped queries explicitly (GEO /
  featured-snippet friendly).
- Add `Organization`/`WebSite` structured data. `FAQPage`/`HowTo` no longer
  produce Google rich results (HowTo removed 2023; FAQ removed 2026) — if used
  at all, treat them as semantic data only, and put the Q&A as visible HTML
  text right after the heading rather than relying on the schema.
- Keep descriptive, unique title/description and strong internal links.
- Avoid heavy client-rendering walls, interstitial overlays and paywalls for
  crawlers.

### 5. hreflang (missing on many multilingual sites)

For sites with language/region variants, add in `<head>`:

```html
<link rel="alternate" hreflang="en" href="https://example.com/" />
<link rel="alternate" hreflang="es" href="https://example.com/es/" />
<link rel="alternate" hreflang="x-default" href="https://example.com/" />
```

Rules: reciprocal on every variant, one canonical per language, `x-default`
points to the fallback, and the sitemap alternates mirror the `<head>` tags.

## SEO Content Checklist

**Before Publishing:**
- [ ] Primary keyword in title tag (under 60 chars)
- [ ] Meta description (150-160 chars, compelling)
- [ ] H1 tag with primary keyword
- [ ] URL slug optimized and readable
- [ ] Images compressed with descriptive alt text
- [ ] 3-5 internal links to relevant content
- [ ] External links to authoritative sources
- [ ] Content length appropriate for topic depth
- [ ] Schema markup implemented
- [ ] Mobile-friendly and responsive
- [ ] Page speed optimized (< 3s load time)
- [ ] No broken links
- [ ] Canonical tag set correctly
- [ ] og:image absolute URL + secure_url + type (jpeg/png); width/height equal the real file when declared
- [ ] og:description / twitter:description self-contained (~80–200 chars, key info first)
- [ ] og:image validated with no warnings on Facebook Debugger / LinkedIn Inspector

## Advanced SEO Strategies

### Topic Clusters & Pillar Pages

**Structure:**
```
Pillar Page: "Complete Guide to React"
  ├── Cluster: "React Hooks Tutorial"
  ├── Cluster: "React Context API Guide"
  ├── Cluster: "React Performance Optimization"
  └── Cluster: "React Testing Best Practices"
```

**Implementation:**
- Create comprehensive pillar content (3,000+ words)
- Develop 8-12 cluster articles supporting the pillar
- Link all clusters back to pillar page
- Link pillar page to all clusters
- Use consistent keyword themes

### Featured Snippet Optimization

**Question-Based Content:**
```markdown
## What is React?

React is a JavaScript library for building user interfaces,
developed by Facebook. It allows developers to create reusable
UI components and efficiently update the DOM through a virtual
DOM implementation.
```

**List-Based Content:**
```markdown
## Top 5 React Best Practices

1. Use functional components with hooks
2. Implement proper state management
3. Optimize performance with React.memo
4. Follow component composition patterns
5. Write comprehensive tests
```

**Table-Based Content:**
| Framework | Performance | Learning Curve | Ecosystem |
|-----------|-------------|----------------|-----------|
| React     | Excellent   | Moderate       | Extensive |
| Vue       | Excellent   | Easy           | Growing   |
| Angular   | Good        | Steep          | Mature    |

## Local SEO (for businesses with physical locations)

**Google Business Profile Optimization:**
- Complete all business information
- Regular posts and updates
- Respond to reviews
- Add high-quality photos
- Verify business hours

**Local Schema Markup:**
```json
{
  "@type": "LocalBusiness",
  "name": "Tech Solutions Inc",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "San Francisco",
    "addressRegion": "CA",
    "postalCode": "94102"
  },
  "telephone": "+1-415-555-0123"
}
```

## Monitoring & Analytics

**Key Metrics to Track:**
- Organic traffic trends
- Keyword rankings
- Click-through rates (CTR)
- Bounce rate and dwell time
- Core Web Vitals scores
- Backlink profile growth
- Conversion rates from organic traffic

**Tools:**
- Google Search Console (performance, indexing issues)
- Google Analytics 4 (traffic, behavior, conversions)
- PageSpeed Insights (Core Web Vitals)
- Ahrefs/SEMrush (keywords, backlinks, competition)
- Screaming Frog (technical audits)

When optimizing for SEO, prioritize user experience and value delivery. Search engines increasingly reward content that genuinely helps users and provides authoritative, trustworthy information.
