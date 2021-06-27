import strformat
import options
import config
import osproc
import random
import os

type DbusProxy* = object
  process*: Process
  socket*: string
  args: seq[string]

proc exec*(proxy: DbusProxy): Process =
  # todo: start dbus proxy in bwrap
  # todo: pass arguments as fd
  startProcess("xdg-dbus-proxy", args = proxy.args,
    options = {poEchoCmd, poParentStreams, poUsePath})

proc startDBusProxy*(config: Config, hostname: string): DbusProxy =
  let busPath = getEnv("DBUS_SESSION_BUS_ADDRESS")
  let runtimeDir = getEnv("XDG_RUNTIME_DIR")

  if busPath == "" or runtimeDir == "":
    raise newException(IOError, "DBUS_SESSION_BUS_ADDRESS and XDG_RUNTIME_DIR are required")

  let id = rand(1000)
  let filterName = &"dbus-proxy-{hostname}-{id}"

  var proxy = DbusProxy()
  proxy.socket = &"{runtimeDir}/{filterName}"

  proxy.args.add(busPath)
  proxy.args.add(proxy.socket)

  for name in config.dbussee.get(@[]):
    proxy.args.add(&"--see={name}")

  for name in config.dbustalk.get(@[]):
    proxy.args.add(&"--talk={name}")

  for name in config.dbuscall.get(@[]):
    proxy.args.add(&"--call={name}")

  for name in config.dbusown.get(@[]):
    proxy.args.add(&"--own={name}")

  for name in config.dbusbroadcast.get(@[]):
    proxy.args.add(&"--broadcast={name}")

  proxy.args.add("--filter")
  proxy.args.add("--log")
  proxy.process = proxy.exec()

  proxy