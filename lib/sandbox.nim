import os
import args
import utils
import modes
import bwrap
import config
import options

proc sandboxExec*(mode: Modes, args: Args) =
  var call = BwrapCall()
  var userConfig = none(Config)

  let hostname = args.name.get("sandbox")
  let profilePath = getProfilePath(args, mode)

  if args.name.isSome:
    let name = args.name.unsafeGet
    let sandboxPath = getSandboxPath(name)
    let sandboxFiles = sandboxPath.joinPath("files")
    let configPath = sandboxPath.joinPath("config.json")

    if fileExists(configPath):
        userConfig = some(loadConfig(configPath))

    createDir(sandboxFiles)
    call.addArg("--bind", sandboxFiles, getHomeDir())

  var profile = loadConfig(profilePath)
  profile.extendConfig()

  call
    .addMount("--dev-bind", "/dev/null")
    .addArg("--tmpfs", "/tmp")
    .addArg("--proc", "/proc")
    .addArg("--unshare-all")
    .addArg("--share-net")
    .addArg("--die-with-parent")
    .applyConfig(profile)

  if mode == Modes.Shell:
    call
      .addMount("--bind", getCurrentDir())
      .addArg("--chdir", getCurrentDir())
      .addArg("--hostname", hostname)

  if userConfig.isSome:
    call.applyConfig(userConfig.unsafeGet)

  call.addArg(args.getCmd).exec()
