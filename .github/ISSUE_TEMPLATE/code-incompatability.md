---
name: Code incompatability
about: Report an incompatible piece of code or an edge case
title: Compatability issue
labels: bug
assignees: Hexcede

---

**Describe the bug**
This code does not run as expected, causes hanging, or other compatibility issues.

**To Reproduce**
Describe what the incorrect behaviour is.

This code demonstrates the issue as best as possible and is as small as possible:
```lua
local sandbox = H6x.Sandbox.new()
sandbox:ExecuteCode([[ CODE HERE ]])
```

**Expected behavior**
Describe what the correct behaviour would be.

This code demonstrates the expected behaviour when ran outside of the sandbox (leave unchanged if N/A):
```lua
CODE HERE
```

**Version information (please complete the following information):**
 - H6x version: [e.g. v1.1.220607]
 - Beta features enabled: [Which Beta features you've enabled in Studio]

**Additional context**
Add any other context about the problem here.
