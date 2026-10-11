# Regenerate the README demo GIF:
#
#   brew install vhs          # or: go install github.com/charmbracelet/vhs@latest
#   vhs Misc/demo/none-aware.tape
#
# Expects a built interpreter at ./python (./python.exe on macOS).

Output Misc/demo/none-aware.gif

Set Shell "bash"
Set FontSize 20
Set Width 1000
Set Height 540
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

Hide
Type "PY=$PWD/python; [ -x ./python.exe ] && PY=$PWD/python.exe; mkdir -p /tmp/vhs-bin; ln -sf $PY /tmp/vhs-bin/python3.16; export PATH=/tmp/vhs-bin:$PATH; clear"
Enter
Show

Type "python3.16 --version"
Enter
Sleep 1s

Type "python3.16 -q"
Enter
Sleep 1s

Type "class User:        name = 'ALICE'"
Enter
Type "class Response:    customer = User()"
Enter
Enter
Sleep 500ms

Type "print(Response()?.customer?.name.lower())"
Enter
Sleep 1.5s

Type "Response.customer = None"
Enter
Type "print(Response()?.customer?.name.lower())"
Enter
Sleep 1.5s

Type "response = None"
Enter
Type "print(response?.customer?.name.lower())"
Enter
Sleep 1.5s

Type "# only None short-circuits, and skipped args are never evaluated"
Enter
Type "print(repr(''?.upper()), None?.f(1 / 0))"
Enter
Sleep 3s
