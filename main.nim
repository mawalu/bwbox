import lib/sandbox
import lib/args
import options
import random

proc main(): int =
  let args = parseArgs()
  echo args

  if args.isNone:
    echo "Usage: bwshell --name=sandbox_name --profile=profile <sandbox_cmd>"
    return 1
  else:
    randomize()
    sandboxExec(args.unsafeGet)

quit(main())
