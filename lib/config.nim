import sequtils
import options
import bwrap
import utils
import json
import os

type Link* = object
  src*: string
  dst*: string

type Config* = object
  extends*: Option[string]
  mount*: Option[seq[string]]
  romount*: Option[seq[string]]
  symlinks*: Option[seq[Link]]
  mountcwd*: Option[bool]
  privileged*: Option[bool]
  sethostname*: Option[bool]
  allowdri*: Option[bool]
  dbus*: Option[bool]
  dbussee*: Option[seq[string]]
  dbustalk*: Option[seq[string]]
  dbusown*: Option[seq[string]]
  dbuscall*: Option[seq[string]]
  dbusbroadcast*: Option[seq[string]]
  devmount*: Option[seq[string]]

proc applyConfig*(call: var BwrapCall, config: Config) =
  for mount in config.mount.get(@[]):
     call.addMount("--bind", checkRelativePath(mount))

  for mount in config.romount.get(@[]):
     call.addMount("--ro-bind", checkRelativePath(mount))

  for symlink in config.symlinks.get(@[]):
     call.addArg("--symlink", symlink.src, symlink.dst)

  for device in config.devmount.get(@[]):
      call.addArg("--dev-bind", device, device)

  if config.mountcwd.get(false):
      call
        .addMount("--bind", getCurrentDir())
        .addArg("--chdir", getCurrentDir())

proc loadConfig*(path: string): Config =
  return readFile(path)
    .parseJson()
    .to(Config)

proc extendConfig*(config: var Config): Config {.discardable.} =
  if config.extends.isNone:
    return

  var eConf = loadConfig(getProfilePath(config.extends.unsafeGet))
  eConf.extendConfig()

  # todo: replace using macro / templates
  config.mount = some(config.mount.get(@[]).concat(eConf.mount.get(@[])))
  config.romount = some(config.romount.get(@[]).concat(eConf.romount.get(@[])))
  config.symlinks = some(config.symlinks.get(@[]).concat(eConf.symlinks.get(@[])))
  config.mountcwd = some(config.mountcwd.get(eConf.mountcwd.get(false)))
  config.sethostname = some(config.sethostname.get(eConf.sethostname.get(false)))
  config.allowdri = some(config.allowdri.get(eConf.allowdri.get(false)))
  config.devmount = some(config.devmount.get(eConf.devmount.get(@[])))

  config.dbus = some(config.dbus.get(eConf.dbus.get(false)))
  config.dbussee = some(config.dbussee.get(@[]).concat(eConf.dbussee.get(@[])))
  config.dbustalk = some(config.dbustalk.get(@[]).concat(eConf.dbustalk.get(@[])))
  config.dbusown = some(config.dbusown.get(@[]).concat(eConf.dbusown.get(@[])))
  config.dbuscall = some(config.dbuscall.get(@[]).concat(eConf.dbuscall.get(@[])))
  config.dbusbroadcast = some(config.dbusbroadcast.get(@[]).concat(eConf.dbusbroadcast.get(@[])))

  return config
