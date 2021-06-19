import lib/sandbox
import lib/modes
import lib/args
import strformat
import strutils
import options
import os

proc main(): int =
  let mode = parseEnum[Modes](paramStr(0), Modes.Shell)
  let args = parseArgs()

  if args.isNone:
    echo &"Usage: {mode} --command=cmd --profile=profile <sandbox_name>"
    return 1
  else:
    sandboxExec(mode, args.unsafeGet)

quit(main())
