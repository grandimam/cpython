#!/usr/bin/env bash
# Printed when a Codespace attaches. Keep it short: show something that works.
cat <<'EOF'

  CPython · Experimental is built and ready.

  Try the None-aware attribute operator:

    ./python -c 'print(None?.upper(), "hi"?.upper())'
    ./python -c 'import dis; dis.dis(lambda r: r?.customer?.name.lower())'

  Or start a REPL:   ./python

EOF
