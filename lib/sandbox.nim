import os
import json
import modes
import bwrap
import config
import options

proc homePath(p: string): string =
  joinPath(getHomeDir(), p)

const CONFIG_LOCATION = homePath(joinPath(".sandboxes", "config.json"))

proc checkRelativePath(p: string): string =
  if p[0] == '/':
    return p
  homePath(p)

proc applyConfig(call: var BwrapCall, config: Config) =
  for mount in config.mount.get(@[]):
     call.addMount("--bind", checkRelativePath(mount))

  for mount in config.romount.get(@[]):
     call.addMount("--ro-bind", checkRelativePath(mount))

  for symlink in config.symlinks.get(@[]):
     call.addArg("--symlink", symlink.src, symlink.dst)

proc loadConfig(path: string): Config =
  return readFile(path).parseJson().to(Config)

proc sandboxExec*(name: string, command: string, mode: Modes) =
  let sandboxPath = homePath(joinPath(".sandboxes", name))
  let sandboxFiles = joinPath(sandboxPath, "files")
  let sandboxInfo = joinPath(sandboxPath, "info")

  createDir(sandboxFiles)
  var call = BwrapCall()

  call
    .addArg("--bind", sandboxFiles, getHomeDir())
    .addMount("--dev-bind", "/dev")
    .addArg("--tmpfs", "/tmp")
    .addArg("--proc", "/proc")
    .addArg("--unshare-all")
    .addArg("--share-net")
    .addArg("--die-with-parent")
    .addArg("--hostname", name)
    .applyConfig(loadConfig(CONFIG_LOCATION))

  if mode == Modes.Shell:
    call
      .addMount("--bind", getCurrentDir())
      .addArg("--chdir", getCurrentDir())

  let configPath = sandboxPath.joinPath("config.json")
  if fileExists(configPath):
    call.applyConfig(loadConfig(configPath))

  call.addArg(command).exec()
