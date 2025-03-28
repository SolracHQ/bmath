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
# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
