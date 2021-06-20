import os
import args
import json
import utils
import bwrap
import config
import options

proc sandboxExec*(args: Args) =
  var call = BwrapCall()
  var configPath = none(string)

  let hostname = args.name.get(getProfile(argst ))

  if args.name.isSome:
    let name = args.name.unsafeGet
    let sandboxPath = getSandboxPath(name)
    let sandboxFiles = sandboxPath.joinPath("files")
    let userConfig = sandboxPath.joinPath("config.json")


    createDir(sandboxFiles)
    call.addArg("--bind", sandboxFiles, getHomeDir())

    if not fileExists(userConfig):
      let newConfig = %* {"extends": getProfile(args)}
      writeFile(userConfig, $newConfig)

    configPath = some(userConfig)

  if configPath.isNone or not fileExists(configPath.unsafeGet):
    configPath = some(getProfilePath(args))

  var config = loadConfig(configPath.unsafeGet)
  config.extendConfig()

  call
    .addMount("--dev-bind", "/dev/null")
    .addMount("--dev-bind", "/dev/random")
    .addMount("--dev-bind", "/dev/urandom")
    .addArg("--tmpfs", "/tmp")
    .addArg("--proc", "/proc")
    .addArg("--unshare-all")
    .addArg("--share-net")
    .addArg("--die-with-parent")
    .addArg("--setenv", "BWSANDBOX", "1")
    .applyConfig(config)

  if config.mountcwd.get(false):
    call
      .addMount("--bind", getCurrentDir())
      .addArg("--chdir", getCurrentDir())

  if config.sethostname.get(false):
    call
      .addArg("--hostname", hostname)

  call.addArg(args.getCmd).exec()
