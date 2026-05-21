# JSX / React Review Rules

Apply these rules to `.jsx` and `.tsx` files, in addition to `js-ts-rules.md`.

---

## BLOCKING

### JSX-B1: Missing `key` prop in list renders
Every element rendered inside `.map()`, `.flatMap()`, or any array/iterator must have a stable, unique `key` prop. Missing keys cause incorrect diffing, duplicated state, and hard-to-reproduce bugs.
```jsx
// BLOCKING
items.map(item => <Item {...item} />)

// Correct
items.map(item => <Item key={item.id} {...item} />)
```
- Flag: `.map(` followed by a JSX return with no `key=` prop on the outermost returned element

### JSX-B2: `dangerouslySetInnerHTML` usage
This prop bypasses React's XSS protection and injects raw HTML. Every usage must be scrutinized.
- If used with unsanitized user input → BLOCKING
- If used with server-controlled or pre-sanitized content → still flag as WARNING with a note to verify the sanitization source

### JSX-B3: Direct DOM manipulation inside a React component
Using `document.getElementById`, `document.querySelector`, or `document.createElement` inside component logic (not in a utility helper) bypasses React's reconciler and causes state/DOM desync.
- Fix: use `useRef` and the ref's `.current` property

### JSX-B4: Multi-line JSX element must use HTML-block indentation
When a JSX element's opening tag spans multiple lines (props broken across lines), format it like a block: break after `<ComponentName`, indent each prop one level (2 spaces) deeper than the tag's column, and place the closing `>` (or `/>` for self-closing) on its own line at the **same indentation column** as the opening `<`. Opening `<` and closing `>` align.

Single-line elements are unaffected.

```jsx
// ✗ flag — props inline-aligned to first prop, `/>` trailing
<UserCard name={user.name}
          avatar={user.avatar}
          onClick={handleClick}
          highlighted />

// ✗ flag — `>` not dedented to column of opening `<`
<UserCard
    name={user.name}
    avatar={user.avatar}
    onClick={handleClick}
    >
  <Badge />
</UserCard>

// ✓ ok — break after `<UserCard`, props indented 2 spaces, `/>` aligned with `<`
<UserCard
  name={user.name}
  avatar={user.avatar}
  onClick={handleClick}
  highlighted
/>

// ✓ ok — opening tag of paired element, `>` aligned with `<`
<UserCard
  name={user.name}
  avatar={user.avatar}
>
  <Badge />
</UserCard>

// ✓ ok — single-line element, no alignment concern
<UserCard name={user.name} onClick={handleClick} />
```

- Indent inside the tag is **2 spaces from the column of the opening `<`**, not aligned to the first prop.
- Do not flag single-line elements regardless of prop count.

---

## WARNING

### JSX-W1: `useEffect` with a missing or incorrect dependency array
A `useEffect` that references variables from the component scope but omits them from the dependency array will stale-close over old values.
```jsx
// WARNING — `userId` is used but not in deps
useEffect(() => {
  fetchUser(userId);
}, []); // should be [userId]
```
- Also flag `useEffect` with no dependency array at all (runs on every render) if the body performs I/O or state updates

### JSX-W2: Inline object or array literals in JSX props
Inline objects/arrays create a new reference on every render, breaking `React.memo` and causing unnecessary child re-renders.
```jsx
// WARNING
<Chart options={{ color: 'blue' }} />  // new object every render
<List items={['a', 'b', 'c']} />       // new array every render
```
- Fix: move to `useMemo`, a constant outside the component, or a state variable

### JSX-W3: Prop spreading onto DOM elements without filtering
Spreading all props onto a DOM element (`<div {...props}>`) can pass non-DOM attributes (e.g., custom props) and cause React warnings or invalid HTML.
- Flag: `<div {...props}>` or `<span {...rest}>` at the outermost JSX element

### JSX-W4: State update after component might be unmounted
Calling a state setter inside an async callback without checking if the component is still mounted causes "Can't perform a React state update on an unmounted component" warnings and potential memory leaks.
- Pattern: `async` function called in `useEffect` that sets state without an `isMounted` guard or AbortController

### JSX-W5: Component defined inside another component's render
Defining a component function inside another component's body causes it to be recreated on every render, losing all state and triggering full remounts.
```jsx
// WARNING
function Parent() {
  function Child() { return <div />; } // recreated every render
  return <Child />;
}
```

### JSX-W6: Missing error boundary around async data components
Components that fetch data and render it without a parent ErrorBoundary will white-screen on fetch errors.
- Flag: components with `useEffect` + fetch that have no apparent error state handling (`error` variable, try/catch, or error display branch)

---

## INFO

### JSX-I1: `React` imported but not used (pre-React 17 artifact)
In React 17+ with the new JSX transform, `import React from 'react'` is not needed for JSX. If the file uses only hooks (also importable from `'react'`), flag this as a cleanup opportunity.

### JSX-I2: Large component files (> 200 lines)
Components over ~200 lines are candidates for splitting into sub-components or extracting custom hooks.

### JSX-I3: Boolean prop shorthand inconsistency
`<Component disabled={true} />` can be written as `<Component disabled />`. Minor style note.
