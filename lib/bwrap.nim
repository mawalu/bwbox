import posix
import sequtils

type BwrapCall* = object
  args: seq[string]

proc addArg*(call: var BwrapCall, args: varargs[string]): var BwrapCall {.discardable.}  =
  for arg in args:
    call.args.add(arg)
  call

proc addMount*(call: var BwrapCall, mType: string, path: string): var BwrapCall {.discardable.} =
  addArg(call, mType, path, path)
  call

proc exec*(call: var BwrapCall) =
  echo call.args
  discard execv("/usr/bin/bwrap", allocCStringArray(@["bwrap"].concat(call.args)))
