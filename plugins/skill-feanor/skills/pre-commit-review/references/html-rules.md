# HTML Review Rules

Apply these rules to `.html` files (non-ERB). For ERB, use `erb-rules.md`.

---

## BLOCKING

### H-B1: Missing `alt` attribute on `<img>`
Every `<img>` tag must have an `alt` attribute. Missing alt is an accessibility violation and fails WCAG 2.1 AA.
- Flag: `<img` without `alt=`
- Exception: decorative images should use `alt=""` (empty string is valid)

### H-B2: Interactive `<div>` or `<span>` without role and keyboard handler
A `<div>` or `<span>` with an `onclick` handler but no `role` attribute and no `onkeydown`/`onkeypress` is a keyboard accessibility blocker.
- Flag: `<div onclick=` or `<span onclick=` without accompanying `role=` and keyboard event
- Fix: use a semantic `<button>` or `<a>` element instead

### H-B3: Form `<input>` without associated `<label>`
Every form input (text, email, password, checkbox, radio, select, textarea) must have an associated label via `<label for="id">` or wrapping `<label>`.
- Exception: inputs with `aria-label` or `aria-labelledby` are acceptable

### H-B4: `javascript:` protocol in `href` or `src`
`href="javascript:void(0)"` and similar patterns are a security smell and cause CSP violations in strict environments.
- Fix: use `<button>` for actions, proper `<a href>` for navigation

### H-B5: Multi-line tag must use HTML-block indentation
When an HTML tag's opening spans multiple lines (attributes broken across lines), format it like a block: break after `<tagname`, indent each attribute one level (2 spaces) deeper than the tag's column, and place the closing `>` (or `/>` for self-closing) on its own line at the **same indentation column** as the opening `<`. Opening `<` and closing `>` align — same convention as paired HTML tags themselves.

Single-line tags are unaffected.

```html
<!-- ✗ flag — attrs inline-aligned to first attr, `>` trailing -->
<input type="text"
       name="username"
       placeholder="Enter name"
       required>

<!-- ✗ flag — `>` not dedented to column of opening `<` -->
<input
    type="text"
    name="username"
    required
    >

<!-- ✓ ok — break after `<input`, attrs indented 2 spaces, `>` aligned with `<` -->
<input
  type="text"
  name="username"
  placeholder="Enter name"
  required
>

<!-- ✓ ok — self-closing form, `/>` aligned with `<` -->
<img
  src="/avatar.png"
  alt="User avatar"
  width="48"
  height="48"
/>

<!-- ✓ ok — single-line tag, no alignment concern -->
<input type="text" name="username" required>
```

- Indent inside the tag is **2 spaces from the column of the opening `<`**, not aligned to the first attribute.
- Do not flag single-line tags regardless of attribute count.

---

## WARNING

### H-W1: Non-semantic structure for navigation, header, footer, main
Using `<div class="nav">`, `<div class="header">`, etc. instead of `<nav>`, `<header>`, `<footer>`, `<main>`, `<aside>` reduces accessibility and SEO.
- Flag: common class names like `class="nav"`, `class="header"`, `class="footer"`, `class="sidebar"` on `<div>` elements

### H-W2: Broken heading hierarchy
Headings must not skip levels (e.g., `<h1>` followed directly by `<h3>`). Each page should have exactly one `<h1>`.
- Flag: multiple `<h1>` tags in a single document, or heading level gaps > 1

### H-W3: Inline `style` attribute
Inline styles couple presentation to markup and make theming and overrides harder.
- Exception: dynamically computed styles set from JavaScript (e.g., `style="width: {{ width }}px"`) are acceptable
- Flag: static inline styles like `style="color: red; font-weight: bold"`

### H-W4: Empty `href="#"` on anchor tags
`<a href="#">` scrolls to the top of the page, which is usually unintended. Use `<button>` for actions.

### H-W5: Missing `lang` attribute on `<html>` tag
The root `<html>` element should declare a `lang` attribute (e.g., `lang="en"`) for screen reader support.
- Only flag if this is a full document (has `<html>` tag), not a partial/component

### H-W6: `<table>` used for layout
Tables should be used for tabular data only, not for page layout.
- Flag: tables with no `<th>` or `scope` attributes, or tables wrapping clearly non-tabular content

### H-W7: Missing `charset` or `viewport` meta (full documents)
Full HTML documents should include `<meta charset="UTF-8">` and `<meta name="viewport" content="width=device-width, initial-scale=1">`.

---

## INFO

### H-I1: `<b>` and `<i>` used instead of `<strong>` and `<em>`
`<b>` and `<i>` are presentational. Prefer `<strong>` (important) and `<em>` (emphasis) for semantic meaning.

### H-I2: Long attribute lines reducing readability
HTML tags with many attributes on a single line (> 120 chars) are hard to read in code review. Suggest breaking attributes across lines.

### H-I3: Commented-out HTML blocks
Large blocks of commented-out HTML should be removed rather than left in source.
