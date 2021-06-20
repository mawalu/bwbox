import lib/sandbox
import lib/args
import options

proc main(): int =
  let args = parseArgs()

  if args.isNone:
    echo "Usage: bwshell --command=cmd --profile=profile <sandbox_name>"
    return 1
  else:
    sandboxExec(args.unsafeGet)

quit(main())
