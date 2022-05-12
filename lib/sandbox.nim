import strutils
import options
import config
import utils
import bwrap
import args
import json
import dbus
import os

proc sandboxExec*(args: Args) =
  var call = BwrapCall()
  var configPath = none(string)

  let hostname = args.name.get(getProfile(args))

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
    .addArg("--dev", "/dev")
    .addMount("--dev-bind", "/dev/random")
    .addMount("--dev-bind", "/dev/urandom")
    .addMount("--ro-bind", "/sys/block")
    .addMount("--ro-bind", "/sys/bus")
    .addMount("--ro-bind", "/sys/class")
    .addMount("--ro-bind", "/sys/dev")
    .addMount("--ro-bind", "/sys/devices")
    .addArg("--tmpfs", "/tmp")
    .addArg("--tmpfs", "/dev/shm")
    .addArg("--proc", "/proc")
    .addArg("--unshare-all")
    .addArg("--share-net")
    .addArg("--die-with-parent")
    .addArg("--setenv", "BWSANDBOX", "1")
    .applyConfig(config)

  if config.sethostname.get(false):
    call
      .addArg("--hostname", hostname)

  if config.dbus.get(false):
    # todo: handle process and cleanup later
    let proxy = startDBusProxy(config, hostname)
    call.addArg("--ro-bind", proxy.socket,
      getEnv("DBUS_SESSION_BUS_ADDRESS").split('=')[1])

    # todo: use fd signaling instead of this
    sleep(100)

  if config.allowdri.get(false):
    enableDri(call)

  # resolve binary path outside of the sandbox
  var cmd = args.getCmd

  echo cmd
  cmd[0] = findExe(cmd[0])

  echo cmd

  call.addArg(cmd).exec()
