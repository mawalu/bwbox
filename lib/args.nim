import parseopt
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

proc parseOpt(args: var Args, key: string, value: string): bool =
  case key
  of "name", "n":
    args.name = some(value)
  of "profile", "p":
    args.profile = some(value)
  else:
    return false

  return true

proc parseArgs*(): Option[Args] =
  var p = initOptParser()
  var args = Args()
  var command = newSeq[string]()

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.val == "" or args.parseOpt(p.key, p.val) == false:
        echo "Invalid argument ", p.val
        return
    of cmdArgument:
      command.add(p.key.string)

  if command.len > 0:
    args.cmd = some(command)

  return some(args)