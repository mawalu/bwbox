import os
import args

const APP_NAME = "bwsandbox"

proc getDataDir*(): string =
  getEnv("XDG_DATA_DIR", getHomeDir().joinPath(".local/share"))

proc checkRelativePath*(p: string): string =
  if p[0] == '/':
    return p
  getHomeDir().joinPath(p)

proc getProfilePath*(profile: string): string =
  getConfigDir()
        .joinPath(APP_NAME)
        .joinPath(profile)

proc getProfilePath*(args: Args): string =
  getProfilePath(args.getProfile())

proc getSandboxPath*(name: string): string =
  getDataDir()
    .joinPath(APP_NAME)
    .joinPath(name)