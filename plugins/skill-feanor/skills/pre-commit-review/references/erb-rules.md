# HTML ERB Template Review Rules

Apply these rules to `.html.erb` and `.erb` files.

---

## BLOCKING

### ERB-B1: `raw()` helper or `.html_safe` on user-controlled content
`raw(value)` and `value.html_safe` mark a string as safe for unescaped HTML output. If the value originates from user input, a database field, or an external API response, this is a direct XSS vulnerability.
```erb
<!-- BLOCKING — user-controlled value rendered raw -->
<%= raw(user.bio) %>
<%= @comment.body.html_safe %>
```
- Exception: strings that are provably constructed entirely from sanitized or hardcoded content (e.g., `"<strong>Hello</strong>".html_safe`) may be downgraded to WARNING
- Fix: use `<%= sanitize(user.bio) %>` or restructure to avoid raw HTML

### ERB-B2: Inline JavaScript with interpolated Ruby values without escaping
Interpolating Ruby values directly into a `<script>` block without proper escaping allows injection attacks.
```erb
<!-- BLOCKING -->
<script>
  var userName = "<%= @user.name %>";
</script>
```
- Fix: use `<%= @user.name.to_json %>` or the `json_escape` helper, or pass data via `data-*` attributes and read from JS

### ERB-B3: SQL-like string construction in template
Raw SQL or query fragments assembled in the view layer (even for display purposes) bypass ActiveRecord's parameterization.
- Flag: strings containing `SELECT`, `INSERT`, `UPDATE`, `WHERE` assembled with interpolation in an ERB file

### ERB-B4: Missing `csrf_meta_tags` in layout templates
Rails layouts that make AJAX requests require the CSRF token. The `<%= csrf_meta_tags %>` helper must be present in the `<head>` of full page layouts.
- Only flag in layout files (`layouts/` directory or files that contain `<html>`/`<head>` structure)

### ERB-B5: Multi-line helper call without parentheses
When a Rails/Ruby helper call inside `<% %>` or `<%= %>` spans more than one line, wrap the arguments in parentheses. Parenless multi-line calls are ambiguous to parse, easy to misread, and break when later edits add a method chain or trailing argument.

Single-line calls remain parenthesis-optional.

```erb
<%# ✓ ok — single line, parens optional %>
<% render "shared/foo", name: :bar, required: true %>
<%= link_to "Edit", edit_user_path(user), class: "btn" %>

<%# ✗ flag — multi-line without parens %>
<% render "shared/foo",
   name: :bar,
   required: true %>

<%= form_with model: @user,
              url: users_path,
              local: true do |f| %>
  ...
<% end %>

<%# ✓ ok — multi-line with parens, args broken onto new lines, `)` dedented %>
<% render(
  "shared/foo",
  name: :bar,
  required: true
) %>

<%= form_with(
  model: @user,
  url: users_path,
  local: true
) do |f| %>
  ...
<% end %>
```

- Applies to common Rails view helpers: `render`, `link_to`, `button_to`, `form_with`, `form_for`, `content_tag`, `tag`, `image_tag`, `image_pack_tag`, `javascript_pack_tag`, `stylesheet_link_tag`, `redirect_to`, `submit_tag`, and any helper invoked inside `<% %>` / `<%= %>`.
- Do not flag: block-form helpers where the block itself spans lines but the argument list is on one line (e.g. `<%= form_with model: @user do |f| %>` followed by block body — the arguments are still single-line).
- Do not flag: bare control flow (`if`, `unless`, `each do |x|`) — this rule targets method/helper calls with arguments.

### ERB-B6: Multi-line helper call must use HTML-block indentation
When a Rails/Ruby helper call inside `<% %>` / `<%= %>` spans multiple lines, format it like an HTML block: break after the opening `(`, indent each argument one level (2 spaces) deeper than the opening ERB tag, and place the closing `)` on its own line at the **same indentation column** as the opening `<%` / `<%=`. Treat the helper call's `(...)` as a block whose opening and closing tokens align — same convention as paired HTML tags.

Single-line helper calls are unaffected.

```erb
<%# ✗ flag — args inline-aligned to opening paren, `)` trailing %>
<%= form_with(model: @user,
              url: users_path,
              local: true) do |f| %>
  <%= f.text_field :name %>
<% end %>

<%# ✗ flag — `)` not dedented to column of <%= %>
<%= form_with(
      model: @user,
      url: users_path
    ) do |f| %>
  <%= f.text_field :name %>
<% end %>

<%# ✓ ok — break after `(`, args indented 2 spaces, `)` aligned with <%= %>
<%= form_with(
  model: @user,
  url: users_path
) do |f| %>
  <%= f.text_field :name %>
<% end %>
```

- Indent inside the call is **2 spaces from the column of the opening ERB tag**, not aligned to the opening `(`.
- Do not flag single-line calls regardless of length.

---

## WARNING

### ERB-W1: Business logic and conditional branching in templates
Complex Ruby logic directly in views (multi-line conditionals, data transformations, method chains) violates the separation of concerns and is hard to test.
```erb
<!-- WARNING — business logic in view -->
<% if @user.orders.select { |o| o.status == 'pending' && o.created_at > 30.days.ago }.any? %>
```
- Fix: move logic to a helper method, a presenter/decorator, or a controller-assigned variable

### ERB-W2: Potential N+1 query pattern
Calling association methods inside an `.each` loop on a collection that was not eager-loaded will trigger one query per iteration.
```erb
<!-- WARNING — likely N+1 -->
<% @users.each do |user| %>
  <%= user.orders.count %>  <!-- query per user -->
<% end %>
```
- Flag: `.each` on a collection followed by association access (`.orders`, `.comments`, `.profile`, etc.) without an apparent `includes()`/`eager_load()` in the controller

### ERB-W3: Hardcoded URLs in templates
URLs to internal routes hardcoded as strings (e.g., `href="/users/1/edit"`) rather than using Rails route helpers break when routes change.
- Fix: use route helpers (`edit_user_path(@user)`)

### ERB-W4: Instance variables directly in partials
Partials should receive data via locals, not by accessing controller instance variables directly. This creates implicit coupling and makes partials impossible to reuse independently.
```erb
<!-- WARNING — partial depending on @user from controller -->
<%= @user.name %>

<!-- Better -->
<%= user.name %>  <!-- where user is passed as a local -->
```

---

## INFO

### ERB-I1: Unused local variable in partial render call
```ruby
render partial: 'card', locals: { title: @title, unused_var: true }
```
Check if all locals passed to a partial are actually used inside it.

### ERB-I2: Long `.each` blocks in templates
ERB `.each` blocks exceeding ~10 lines are candidates for extraction into a partial.

### ERB-I3: Missing `<%= %>` vs `<% %>` distinction
`<% %>` executes Ruby without output. `<%= %>` outputs the result. A common mistake is using `<% %>` when output was intended, resulting in silent missing data. Flag if a non-output tag appears where output is likely intended (heuristic: `.to_s`, `.name`, `.title` calls inside `<% %>`).
