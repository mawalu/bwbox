import parseopt
import options
import modes
import os

type Args* = object
  name*: Option[string]
  cmd*: Option[string]
  profile*: Option[string]

proc getCmd*(args: Args): string =
  return args.cmd.get(getEnv("SHELL", "/bin/bash"))

proc getProfile*(args: Args, mode: Modes): string =
  if args.profile.isSome:
    return args.profile.unsafeGet

  return case mode
  of Modes.Shell: "shell"
  of Modes.Box: "gui"

proc parseOpt(args: var Args, key: string, value: string): bool =
  case key
  of "command", "c":
    args.cmd = some(value)
  of "profile", "p":
    args.profile = some(value)
  else:
    return false

  return true

proc parseArgs*(): Option[Args] =
  var p = initOptParser()
  var args = Args()

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.val == "" or args.parseOpt(p.key, p.val) == false:
        echo "Invalid argument ", p.val
        return
    of cmdArgument:
      args.name = some(p.key.string)

  return some(args)