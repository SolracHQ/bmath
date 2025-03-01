--nimcache:
  ".cache"

when not defined(debug):
  --opt:
    speed
else:
  --debugger:
    on
  --lineDir:
    on
  --debuginfo
  --debugger:
    native
