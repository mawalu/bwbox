import os
import json
import bwrap
import config
import options

const CONFIG_LOCATION = "config.json"

proc homePath(p: string): string =
  joinPath(getHomeDir(), p)

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

proc sandboxExec*(name: string, command: string) =
  let sandboxPath = homePath(joinPath(".sandboxes", name))
  let sandboxFiles = joinPath(sandboxPath, "files")
  let sandboxInfo = joinPath(sandboxPath, "info")

  createDir(sandboxFiles)
  var call = BwrapCall()

  call
    .addArg("--bind", sandboxFiles, getHomeDir())
    .addMount("--dev-bind", "/dev")
    .addArg("--dir", "/tmp")
    .addArg("--proc", "/proc")
    .addArg("--unshare-all")
    .addArg("--share-net")
    .addArg("--die-with-parent")
    .addArg("--hostname", name)
    .addArg("--chdir", getHomeDir())
    .applyConfig(loadConfig(CONFIG_LOCATION))

  let configPath = sandboxPath.joinPath("config.json")
  echo configPath
  if fileExists(configPath):
    call.applyConfig(loadConfig(configPath))

  call.addArg(command).exec()
