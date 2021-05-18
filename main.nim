import lib/sandbox
import strformat
import os

proc main() =
  let mode = splitPath(getAppFilename()).tail
  let args = commandLineParams()
  let argc = paramCount()

  if argc == 0:
    echo &"Usage: {mode} <sandbox> [command]"
    quit(1)

  let name = args[0]
  var command: string

  if argc > 1:
    command = args[1]
  else:
    command = getEnv("SHELL", "/bin/sh")

  sandboxExec(name, command)

main()
