# JavaScript / TypeScript Review Rules

Apply these rules to `.js`, `.mjs`, `.cjs`, and `.ts` files. They also apply as a base layer to `.jsx`, `.tsx`, and `.vue` files — read the corresponding rules file for additional type-specific rules.

---

## BLOCKING

### JT-B1: `debugger` statement
A `debugger` statement pauses execution in any environment with DevTools attached. Must not be pushed.
- Flag: `debugger;` or `debugger` on its own line

### JT-B2: Hardcoded credentials, secrets, or internal URLs
Strings that look like API keys, tokens, passwords, or private internal base URLs should never be committed.
- Flag patterns: `apiKey = "..."`, `password = "..."`, `secret = "..."`, `Bearer <long-string>`, `token: "..."`, long alphanumeric strings (> 20 chars) assigned to security-named variables
- Exception: clearly fake placeholders like `"YOUR_API_KEY_HERE"` or `"<token>"`

### JT-B3: Empty `catch` block
An empty catch silently swallows errors, making debugging impossible and hiding bugs.
```js
// BLOCKING
try { ... } catch (e) {}
try { ... } catch (err) { /* TODO */ }
```
- Exception: catch blocks that explicitly call `return` or `continue` with intent (e.g., `catch { return null; }`) — flag only truly empty or comment-only bodies

### JT-B4: Calling an `async` function without `await` and without handling the returned Promise
```js
// BLOCKING — fire-and-forget with no error handling
async function save() { ... }
save(); // Promise returned and discarded
```
- Flag only when the return value is provably discarded at the call site and the function name suggests it performs I/O or state mutation

### JT-B5: Direct `eval()` usage
`eval()` is a security and performance hazard. Flag any direct call to `eval(` with a dynamic string.

---

## BLOCKING (Code Style — Qiscus Standards)

These rules enforce the organization's coding conventions. Flag violations in newly added lines (diff `+` lines) only — do not flag pre-existing code that wasn't touched in this diff.

### JT-B6: Single quotes used for strings
Use double quotes for all string literals. Single quotes are only acceptable for strings that contain apostrophes (e.g., `"can't"`, `"don't"`). Template literals (backticks) are allowed only when string interpolation is needed.
```js
console.log("hello there");          // ✓ ok
console.log(`hello ${name}`);        // ✓ ok — interpolation
console.log('hello there');          // ✗ flag
console.log(`hello there`);          // ✗ flag — no interpolation needed
```

### JT-B7: Missing semicolons at end of statements
All statements must end with a semicolon. Relying on ASI (Automatic Semicolon Insertion) can cause subtle bugs, especially when a line starts with `[`, `(`, or a template literal.
```js
var name = "ESLint"          // ✗ flag — missing semicolon
var website = "eslint.org";  // ✓ ok
```

### JT-B8: Wrong indentation (not 2 spaces)
Use 2 spaces for indentation. Do not use 4 spaces or tabs.
```js
// ✗ flag
function hello(name) {
    console.log("hi", name);
}

// ✓ ok
function hello(name) {
  console.log("hi", name);
}
```

### JT-B9: Missing space after keywords
Keywords (`if`, `else`, `for`, `while`, `return`, `switch`, `typeof`, etc.) must be followed by a space before the opening parenthesis or brace.
```js
if(condition) { ... }   // ✗ flag
if (condition) { ... }  // ✓ ok
```

### JT-B10: `==` or `!=` instead of `===` or `!==`
Always use strict equality (`===`) and strict inequality (`!==`). Loose equality performs type coercion and causes hard-to-spot bugs.
```js
if (a == b)  { ... }  // ✗ flag
if (a === b) { ... }  // ✓ ok
```

### JT-B11: String concatenation with `+` operator instead of template literals
Use template literals for building strings that include variables. The `+` operator for string concatenation is not allowed.
```js
var message = "hello, " + name + "!";  // ✗ flag
var message = `hello, ${name}!`;       // ✓ ok
```
- Exception: simple two-operand concatenations of two string literals (rare) may be acceptable if no variable is involved

### JT-B12: Missing space after commas
There must be a space after every comma in argument lists, array literals, and object properties.
```js
var list = [1,2,3,4];               // ✗ flag
function greet(name,options) { ... } // ✗ flag
var list = [1, 2, 3, 4];            // ✓ ok
```

### JT-B13: `else` not on the same line as the closing curly brace
The `else` keyword must follow the closing `}` of the preceding `if` block on the same line.
```js
// ✗ flag
if (condition) {
  // ...
}
else {
  // ...
}

// ✓ ok
if (condition) {
  // ...
} else {
  // ...
}
```

### 