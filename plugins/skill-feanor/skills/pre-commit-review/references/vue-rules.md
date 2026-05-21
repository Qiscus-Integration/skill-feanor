# Vue Single-File Component Review Rules

Apply these rules to `.vue` files, in addition to `js-ts-rules.md` for the `<script>` block.

---

## BLOCKING

### VUE-B1: `v-for` without `:key`
Every `v-for` directive must have a `:key` binding with a stable, unique value. Without it, Vue cannot efficiently patch the DOM and produces incorrect behavior with stateful child components.
```html
<!-- BLOCKING -->
<li v-for="item in items">{{ item.name }}</li>

<!-- Correct -->
<li v-for="item in items" :key="item.id">{{ item.name }}</li>
```
- Flag: `v-for` attribute on any element without a `:key` or `v-bind:key` on the same element

### VUE-B2: `v-html` directive with potentially unsanitized content
`v-html` renders raw HTML and bypasses Vue's XSS protection. Any use with dynamic content derived from user input or an external API is a security vulnerability.
- If the content source is a user-controlled field → BLOCKING
- If the content source is internal/server-controlled → flag as WARNING with a note

### VUE-B3: Mutating a prop directly
Props are one-directional. Mutating them inside the child component bypasses Vue's reactivity contract and causes unpredictable bugs.
```js
// BLOCKING
props: ['value'],
methods: {
  update() { this.value = 'new'; } // mutates prop
}
```
- Fix: emit an event and let the parent update, or use a local `data` copy initialized from the prop

### VUE-B4: Multi-line template element must use HTML-block indentation
When a template element's opening tag spans multiple lines (attributes, directives, or bindings broken across lines), format it like a block: break after `<tagname`, indent each attribute/directive one level (2 spaces) deeper than the tag's column, and place the closing `>` (or `/>` for self-closing) on its own line at the **same indentation column** as the opening `<`. Opening `<` and closing `>` align.

Single-line elements are unaffected.

```html
<!-- ✗ flag — attrs inline-aligned to first attr, `>` trailing -->
<UserCard :name="user.name"
          :avatar="user.avatar"
          @click="handleClick"
          v-if="user">
  <Badge />
</UserCard>

<!-- ✗ flag — `>` not dedented to column of opening `<` -->
<UserCard
    :name="user.name"
    :avatar="user.avatar"
    @click="handleClick"
    >
  <Badge />
</UserCard>

<!-- ✓ ok — break after `<UserCard`, attrs indented 2 spaces, `>` aligned with `<` -->
<UserCard
  :name="user.name"
  :avatar="user.avatar"
  @click="handleClick"
  v-if="user"
>
  <Badge />
</UserCard>

<!-- ✓ ok — self-closing form, `/>` aligned with `<` -->
<BaseIcon
  name="check"
  size="lg"
  :spin="loading"
/>

<!-- ✓ ok — single-line element, no alignment concern -->
<UserCard :name="user.name" @click="handleClick" />
```

- Indent inside the tag is **2 spaces from the column of the opening `<`**, not aligned to the first attribute.
- Do not flag single-line elements regardless of attribute count.

---

## WARNING

### VUE-W1: `$parent` direct access
Accessing `this.$parent` creates tight coupling between parent and child components, breaks component reuse, and makes the data flow impossible to reason about.
- Fix: use props + events, provide/inject, or a state store

### VUE-W2: Props without type definitions
All props should declare a `type` (and ideally `required` or `default`) so Vue can validate them at runtime and developers understand the component's contract.
```js
// WARNING — no type
props: ['label', 'count']

// Better
props: {
  label: { type: String, required: true },
  count: { type: Number, default: 0 }
}
```

### VUE-W3: `watch` without `deep` when watching an object that changes internally
Watching an object reference without `deep: true` will not fire when nested properties change, leading to silent reactivity failures.
```js
// WARNING — may silently miss nested changes
watch: {
  config(val) { this.rebuild(val); }
}
```

### VUE-W4: Business logic directly in template expressions
Complex JavaScript expressions inline in templates (ternaries inside ternaries, method chains, multiple conditions) make templates hard to read and test.
- Flag: template expressions longer than ~50 characters or containing nested ternaries
- Fix: move logic to a computed property or method

### VUE-W5: Component without `name` option (Vue 2) or `defineComponent` name (Vue 3)
Anonymous components produce unhelpful names in Vue DevTools and error messages.
```js
// WARNING
export default {
  // no name property
  data() { return {}; }
}
```

### VUE-W6: Using `$set` / `Vue.set` in Vue 3
`Vue.set` and `this.$set` are Vue 2 APIs removed in Vue 3. Flag in Vue 3 codebases and suggest using reactive assignments directly.

### VUE-W7: Watchers used where a computed property would be cleaner
A `watch` that updates a `data` property when another `data`/`prop` changes can almost always be replaced with a `computed` property, which is more declarative and efficient.

---

## INFO

### VUE-I1: Component not using PascalCase naming
Vue recommends PascalCase for component names both in the SFC filename and in the `name` option (e.g., `UserProfile`, not `userProfile` or `user-profile`).

### VUE-I2: `<style>` block not scoped in a leaf component
Leaf (non-layout) components using unscoped `<style>` can inadvertently affect sibling or child components. Consider `<style scoped>`.

### VUE-I3: Deeply nested template structure
Template trees more than ~5 levels deep are a candidate for extracting child components.
