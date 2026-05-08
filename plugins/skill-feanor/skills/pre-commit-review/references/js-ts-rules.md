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
Use double quotes for all string literals. Single quotes are only acceptable in these cases:
1. The string contains apostrophes (e.g., `"can't"`, `"don't"`).
2. The string is **nested inside a template-literal interpolation** (`${...}`) where the outer template uses backticks. Switching to double quotes here would clash with surrounding attribute or string delimiters.
3. The string is **nested inside a double-quoted attribute or string** where doubling up would require escaping (e.g., HTML/JSX/Vue attributes, JSON-in-string).

Template literals (backticks) are allowed only when string interpolation is needed.
```js
console.log("hello there");                                   // ✓ ok
console.log(`hello ${name}`);                                 // ✓ ok — interpolation
console.log('hello there');                                   // ✗ flag
console.log(`hello there`);                                   // ✗ flag — no interpolation needed

// ✓ ok — single quotes inside ${...} of a template literal
:class="`flex items-center gap-2 h-7 ${disabled ? '' : 'bg-gray-shade'}`"

// ✓ ok — single quotes inside a double-quoted attribute
<div title="it's fine"></div>
```
- Do not flag: single-quoted strings appearing inside `${...}` of a template literal.
- Do not flag: single-quoted strings nested inside a double-quoted attribute value or string where escaping would otherwise be required.

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

### JT-B14: Multi-line `if` without curly braces
When the body of an `if` statement spans multiple lines, curly braces are required. Single-line `if` bodies on the same line are acceptable.
```js
// ✓ ok — single line
if (condition) console.log("foo");

// ✗ flag — multi-line without braces
if (condition)
  console.log("foo");

// ✓ ok
if (condition) {
  console.log("foo");
}
```

### JT-B15: Ternary operator with `?` or `:` at end of line (multi-line form)
In a multi-line ternary, `?` and `:` must be placed at the beginning of the continuation line, not at the end of the preceding line.
```js
// ✗ flag
var location = env.development ?
  "localhost" :
  "www.api.com";

// ✓ ok
var location = env.development
  ? "localhost"
  : "www.api.com";

// ✓ ok — single line
var location = env.development ? "localhost" : "www.api.com";
```

### JT-B16: Non-camelCase variable or function names
Variables and functions must use camelCase. Snake_case, PascalCase (except for classes/constructors/React components), and kebab-case identifiers are not allowed.
```js
function my_function() { }  // ✗ flag
var my_var = "hello";       // ✗ flag
function myFunction() { }   // ✓ ok
var myVar = "hello";        // ✓ ok
```
- Exception: PascalCase is correct for class definitions, constructor functions, and React components
- Exception: UPPER_SNAKE_CASE is acceptable for module-level constants

### JT-B17: File does not end with a newline
Every file must end with a single trailing newline character. This is a UNIX convention that prevents issues with file concatenation and shell output.
- Flag: files where the last line has no trailing newline (visible in diffs as `\ No newline at end of file`)

### JT-B18: Missing space between colon and value in object literals
Object key-value pairs must have a space after the colon and no space before it.
```js
var obj = { "key" : "value" };  // ✗ flag — space before colon
var obj = { "key":"value" };    // ✗ flag — no space after colon
var obj = { "key": "value" };   // ✓ ok
```

### JT-B19: `new Array(...)` constructor instead of array literal
Use array literal syntax `[]` instead of the `Array` constructor. The constructor has ambiguous behavior when called with a single numeric argument.
```js
var nums = new Array(1, 2, 3);  // ✗ flag
var nums = [1, 2, 3];           // ✓ ok
```

### JT-B20: Padding lines inside blocks
Do not add blank lines immediately after an opening `{` or immediately before a closing `}` in blocks (if, for, function, etc.).
```js
// ✗ flag
if (user) {

  const name = getName();

}

// ✓ ok
if (user) {
  const name = getName();
}
```

### JT-B21: Missing space before opening brace of a block
There must be a space between the closing parenthesis (or keyword) and the opening `{` of a block.
```js
if (admin){...}   // ✗ flag
if (admin) {...}  // ✓ ok
```

### JT-B22: Single-line `//` comment used for explanatory text
Use `/* ... */` for all explanatory, descriptive, or documentation comments. The `//` style is reserved exclusively for commenting out code (i.e., code that has been temporarily disabled).
```js
// ✗ flag — // used for explanation
// This function calculates the total price
function calcTotal(items) { ... }

// ✓ ok — /* */ used for explanation
/* This function calculates the total price */
function calcTotal(items) { ... }

// ✓ ok — // used to comment out code
// console.log("debug value:", items);
// return items.reduce((a, b) => a + b, 0);
```
- Flag: `//` lines in newly added code where the content reads as natural language explanation (starts with a capital letter, forms a sentence, describes intent) rather than disabled code
- Do not flag: `//` lines whose content looks like code syntax (starts with a keyword, function call, variable declaration, etc.)
- Do not flag: `// eslint-disable`, `// @ts-expect-error`, `// TODO`, `// FIXME`, or other tool-directive comments

### JT-B23: Redundant or obvious comments
Do not add comments that merely restate what the code already clearly expresses. If a reader can understand what a line or block does just by reading it, the comment adds noise rather than value.
```js
/* Increment the counter */
counter++;

/* Loop through the users */
users.forEach(user => { ... });

/* Check if user is logged in */
if (user.isLoggedIn) { ... }

/* Return the result */
return result;

/* Set the title */
this.title = response.title;
```
All of the above should be flagged — the comment says nothing the code doesn't already say.

A comment is worth keeping when it explains **why** something is done, a non-obvious edge case, a workaround, a business rule, or an intentional deviation from the obvious approach:
```js
/* Delay needed to allow the DOM to settle before measuring — requestAnimationFrame alone is insufficient here */
setTimeout(() => measure(), 50);

/* Price is stored in cents to avoid floating-point rounding errors */
const priceInCents = Math.round(price * 100);
```

- Flag: `/* ... */` comments (per JT-B22, `//` is for commented-out code) whose text is a plain restatement of the immediately following line or block — paraphrases of the identifier names, action verbs that mirror the method being called, or labels that repeat the variable being assigned
- Do not flag: comments that explain intent, reasoning, constraints, or context that is not derivable from the code itself

---

## WARNING

### JT-W1: `console.log`, `console.warn`, `console.error` in non-test, non-utility code
Debug logging left in production code clutters the console and can leak sensitive data.
- Exception: files in a `logger`, `monitoring`, or `analytics` directory; files explicitly named `logger.*`, `debug.*`
- Exception: `console.error` used as a deliberate error boundary (rare — use judgment)

### JT-W2: Commented-out code blocks
Blocks of commented-out code (more than 2 lines) should be deleted, not committed. Use git history to recover old code.

### JT-W3: `var` declarations
`var` has function scope and hoisting semantics that lead to subtle bugs. Use `const` or `let`.

### JT-W4: `any` type in TypeScript
`any` defeats TypeScript's type system. Use proper types, `unknown`, or generics instead.
- Exception: `any` in `.d.ts` declaration files or legitimate escape hatches with a `// eslint-disable-next-line` comment explaining the reason

### JT-W5: `@ts-ignore` and `@ts-nocheck`
These suppress TypeScript errors rather than fixing them. Flag all occurrences.
- Exception: `@ts-expect-error` with a comment explaining why is acceptable

### JT-W6: `setTimeout` or `setInterval` without stored reference
Timers that are started but never cleared (no reference stored for later `clearTimeout`/`clearInterval`) cause memory leaks and unexpected behavior after component unmount.

### JT-W7: `TODO` or `FIXME` in newly added lines
New code introducing TODO/FIXME comments should be called out. Distinguish newly added lines (in the diff's `+` lines) from pre-existing ones.

### JT-W8: Non-null assertion `!` overuse (TypeScript)
Using `!` to assert non-null (e.g., `element!.value`) without a guard is a common source of runtime errors. Flag when used without a preceding null check in the same scope.

### JT-W9: `document.cookie` direct access
Accessing `document.cookie` directly bypasses cookie security attributes. Flag and recommend using a cookie library or HttpOnly flag via server.

### JT-W10: Mutation of function arguments
Directly mutating a parameter object/array inside a function is a hidden side effect that breaks caller expectations.
```js
// WARNING
function process(data) {
  data.status = 'processed'; // mutates caller's object
}
```

---

## INFO

### JT-I1: Unused imports
Import statements for identifiers that are never used in the file. Modern bundlers tree-shake these, but they add noise.

### JT-I2: Magic numbers
Numeric literals used directly in logic without explanation (e.g., `if (count > 47)`) should be named constants.
- Exception: 0, 1, -1, 100 are generally fine without naming

### JT-I3: Long functions (> 60 lines)
Functions exceeding ~60 lines are hard to test and review. Flag as a suggestion to extract sub-functions.

### JT-I4: Deeply nested callbacks (callback hell)
Functions nested more than 3 levels deep as callbacks are hard to read and test. Suggest refactoring to `async/await` or extracting named functions.
