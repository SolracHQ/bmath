--nimcache:".cache"

when not defined(debug):
  --opt:size
else:
  --debugger:on
  --lineDir:on 
  --debuginfo 
  --debugger:native
