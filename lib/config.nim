import sequtils
import options
import bwrap
import utils
import json

type Link* = object
  src*: string
  dst*: string

type Config* = object
  extends*: Option[string]
  mount*: Option[seq[string]]
  romount*: Option[seq[string]]
  symlinks*: Option[seq[Link]]

proc applyConfig*(call: var BwrapCall, config: Config) =
  for mount in config.mount.get(@[]):
     call.addMount("--bind", checkRelativePath(mount))

  for mount in config.romount.get(@[]):
     call.addMount("--ro-bind", checkRelativePath(mount))

  for symlink in config.symlinks.get(@[]):
     call.addArg("--symlink", symlink.src, symlink.dst)

proc loadConfig*(path: string): Config =
  return readFile(path)
    .parseJson()
    .to(Config)

proc extendConfig*(config: var Config): Config {.discardable.} =
  if config.extends.isNone:
    return

  var eConf = loadConfig(getProfilePath(config.extends.unsafeGet))
  eConf.extendConfig()

  config.mount = some(config.mount.get(@[]).concat(eConf.mount.get(@[])))
  config.romount = some(config.romount.get(@[]).concat(eConf.romount.get(@[])))
  config.symlinks = some(config.symlinks.get(@[]).concat(eConf.symlinks.get(@[])))

  return config
