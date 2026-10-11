<div align="center">

<img src="https://www.python.org/static/community_logos/python-logo-generic.svg" alt="Python" width="320" />

# CPython · Experimental

**A playground fork of CPython where speculative language ideas get real implementations.**

[![Based on CPython](https://img.shields.io/badge/based%20on-CPython%203.16%20(main)-3776AB?logo=python&logoColor=white)](https://github.com/python/cpython)
[![Status](https://img.shields.io/badge/status-experimental-orange)](#-caveats)
[![License](https://img.shields.io/badge/license-PSF-blue)](LICENSE)
[![Maintained by @grandimam](https://img.shields.io/badge/maintained%20by-%40grandimam-000000?logo=x&logoColor=white)](https://x.com/grandimam_)

[Quick start](#-quick-start) · [What's new](#-whats-new-in-this-fork) · [Try it](#-try-it) · [How it works](#-how-it-works) · [Caveats](#-caveats)

<br/>

<img src="Misc/demo/none-aware.gif" alt="Demo: response?.customer?.name.lower() returns None instead of raising AttributeError" width="800" />

</div>

---

> [!NOTE]
> This is **not** the official Python distribution. It tracks upstream
> [`python/cpython`](https://github.com/python/cpython) `main` and layers experimental
> syntax and runtime features on top. Maintained by
> [**@grandimam**](https://x.com/grandimam_) — follow along on X for progress and
> write-ups. The upstream README is preserved as [`README.rst`](README.rst).

## ⚡ Quick start

### Zero install — open in Codespaces

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/grandimam/cpython?quickstart=1)

One click gives you a cloud VS Code with the interpreter already compiled.
When the terminal opens, just run:

```bash
./python -c 'print(None?.upper(), "hi"?.upper())'   # None HI
```

> Codespaces runs on *your* GitHub account's free quota (120 core-hours/month
> on personal accounts — no paid plan required). The first build takes a few
> minutes; the interpreter is ready when the welcome message appears.

### Build from source

Takes about five minutes on macOS / Linux:

```bash
git clone https://github.com/grandimam/cpython.git
cd cpython
./configure --enable-optimizations
make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
./python -c 'print("hello"?.upper(), None?.upper())'   # HELLO None
```

> On macOS the built binary is `./python.exe` (case-insensitive filesystem); on Linux it's `./python`.

Prefer a throwaway, side-by-side install so your system Python is untouched:

```bash
./configure --prefix="$HOME/.local/cpython-experimental"
make -j8 && make altinstall
"$HOME/.local/cpython-experimental/bin/python3.16" --version
# Python 3.16.0a0+grandimam.0.1
```

<details>
<summary><strong>Build prerequisites</strong></summary>

- **macOS:** `xcode-select --install` and `brew install openssl xz gdbm`
- **Debian / Ubuntu:** `sudo apt install build-essential pkg-config libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev`
- **Fedora:** `sudo dnf builddep python3`
- **Windows:** `PCbuild\build.bat -c Release` (see [`PCbuild/readme.txt`](PCbuild/readme.txt))

Full details live in the upstream [Developer's Guide](https://devguide.python.org/getting-started/setup-building/).

</details>

## ✨ What's new in this fork

### `?.` — None-aware attribute access

Stop writing `x.y if x is not None else None` chains. The new `?.` operator
short-circuits the **entire** attribute / subscript / call chain to `None` the
moment it hits a `None`:

```python
class User:
    name: str | None

class Response:
    customer: User | None

# Lowercase name or None
name = response?.customer?.name.lower()
```

| Expression                   | `response` is `None` | `customer` is `None` | both set         |
| ---------------------------- | -------------------- | -------------------- | ---------------- |
| `response?.customer?.name.lower()` | `None`         | `None`               | `"alice"`        |
| `response.customer.name.lower()`   | `AttributeError` | `AttributeError`   | `"alice"`        |

**Semantics at a glance**

- Only `None` short-circuits — `""?.upper()` is `""`, `0?.real` is `0`.
- Short-circuiting covers the whole chain: in `x?.f(expensive())`, `expensive()`
  is **never called** when `x is None`.
- It stops at the end of the chain: `x?.a + 1` still raises `TypeError` for `x = None`.
- Load-only: `x?.a = 1`, `del x?.a` and `x?.a += 1` are syntax errors.
- Fully integrated: new `QUESTIONDOT` token, `ast.NoneAwareAttribute` node,
  `ast.unparse` round-trips, `dis` shows the short-circuit, feature-version gated
  (`ast.parse(src, feature_version=(3, 15))` rejects it).

## 🧪 Try it

```python
>>> import ast, dis
>>> ast.dump(ast.parse("a?.b.c", mode="eval").body)
"Attribute(value=NoneAwareAttribute(value=Name(id='a'), attr='b'), attr='c')"

>>> def f(r): return r?.customer?.name.lower()
>>> dis.dis(f)
  1           RESUME                   0
              LOAD_FAST                0 (r)
              COPY                     1
              POP_JUMP_IF_NONE        40 (to L1)
              NOT_TAKEN
              LOAD_ATTR                0 (customer)
              COPY                     1
              POP_JUMP_IF_NONE        26 (to L1)
              NOT_TAKEN
              LOAD_ATTR                2 (name)
              LOAD_ATTR                4 (lower)
              PUSH_NULL
              CALL                     0
      L1:     RETURN_VALUE
```

Run the feature's test-suite:

```bash
./python -m test test_grammar test_ast test_tokenize test_unparse test_syntax
```

## 🔬 How it works

Each feature is implemented end-to-end, the same way a real CPython change would be:

| Layer      | Files                                                   | What changed for `?.`                                          |
| ---------- | ------------------------------------------------------- | -------------------------------------------------------------- |
| Tokenizer  | `Grammar/Tokens`, `Parser/token.c`                      | New two-character `QUESTIONDOT` token                          |
| Grammar    | `Grammar/python.gram`, `Parser/parser.c`                | `primary: primary '?.' NAME`; excluded from assignment targets |
| AST        | `Parser/Python.asdl`, `Python/Python-ast.c`             | `NoneAwareAttribute(expr value, identifier attr)`              |
| Validation | `Python/ast.c`, `Python/symtable.c`                     | Load-only checks, scope analysis                               |
| Codegen    | `Python/codegen.c`                                      | Chain-aware compilation with a shared `POP_JUMP_IF_NONE` label |
| Stdlib     | `Lib/_ast_unparse.py`, `Lib/token.py`                   | Unparsing and token names                                      |
| Docs/Tests | `Doc/reference/expressions.rst`, `Lib/test/test_*.py`  | Language reference, What's New, regression tests               |

Regenerate derived files after touching the grammar or ASDL:

```bash
make regen-token regen-ast regen-pegen
```

## 🗺️ Roadmap

- [x] `?.` None-aware attribute access
- [ ] `?[]` None-aware subscription
- [ ] `??` None-coalescing operator
- [ ] `??=` None-coalescing augmented assignment

Have an idea? [Open an issue](https://github.com/grandimam/cpython/issues) or
ping [@grandimam](https://x.com/grandimam_).

## ⚠️ Caveats

- **Experimental.** Syntax, AST shapes and bytecode may change or disappear without notice.
- **Not for production.** Code written against this fork will not run on official CPython.
- **Tracks `main`.** Expect rebases; pin a commit if you depend on it.
- **Upstream policy.** This fork follows CPython's
  [AI tools policy](https://devguide.python.org/getting-started/ai-tools/) and
  coding conventions so that features could, in principle, be proposed upstream.

## 📄 License

Copyright © 2001 Python Software Foundation. All rights reserved.
Distributed under the [PSF License](LICENSE). See [`README.rst`](README.rst)
for the full upstream copyright and license information.

<div align="center">
<sub>Built with ❤️ by <a href="https://x.com/grandimam_">@grandimam</a> on top of the amazing work of the CPython core team.</sub>
</div>
