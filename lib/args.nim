import options
import os

type Args* = object
  name*: Option[string]
  cmd*: Option[seq[string]]
  profile*: Option[string]
  debug*: bool

proc getCmd*(args: Args): seq[string] =
  return args.cmd.get(@[getEnv("SHELL", "/bin/sh")])

proc getProfile*(args: Args): string =
  if args.profile.isSome:
    return args.profile.unsafeGet

  return "default"

proc parseArgs*(): Option[Args] =
  var args = Args(debug: false)

  var command = newSeq[string]()
  var parsingSandboxArgs = true
  var i = 1

  while i <= paramCount():
    var arg = paramStr(i)

    if arg == "--name" and parsingSandboxArgs:
      args.name = some(paramStr(i + 1))
      i += 2
    elif arg == "--profile" and parsingSandboxArgs:
      args.profile = some(paramStr(i + 1))
      i += 2
    elif arg == "--debug" and parsingSandboxArgs:
      args.debug = true
      i += 1
    else:
      parsingSandboxArgs = false
      command.add(arg)
      i += 1

  if command.len > 0:
    args.cmd = some(command)

  if args.name.isSome or args.cmd.isSome or args.profile.isSome:
    return some(args)
  else:
    return none(Args)
