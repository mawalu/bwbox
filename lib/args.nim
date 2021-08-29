import options
import os

type Args* = object
  name*: Option[string]
  cmd*: Option[seq[string]]
  profile*: Option[string]

proc getCmd*(args: Args): seq[string] =
  return args.cmd.get(@[getEnv("SHELL", "/bin/bash")])

proc getProfile*(args: Args): string =
  if args.profile.isSome:
    return args.profile.unsafeGet

  return "default"

proc parseArgs*(): Option[Args] =
  var args = Args()

  var command = newSeq[string]()
  var i = 1

  while i <= paramCount():
    var arg = paramStr(i)

    if arg == "--name":
      args.name = some(paramStr(i + 1))
      i += 2
    elif arg == "--profile":
      args.profile = some(paramStr(i + 1))
      i += 2
    else:
      echo arg
      command.add(arg)
      i += 1

  if command.len > 0:
    args.cmd = some(command)

  return some(args)