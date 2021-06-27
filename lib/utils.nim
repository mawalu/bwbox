import strformat
import posix
import bwrap
import args
import os

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

proc deviceExists(path: string): bool =
  var res: Stat
  return stat(path, res) >= 0 and S_ISCHR(res.st_mode)

# https://github.com/flatpak/flatpak/blob/1bdbb80ac57df437e46fce2cdd63e4ff7704718b/common/flatpak-run.c#L1496
proc enableDri*(call: var BwrapCall) =
  const mounts = [
    "/dev/dri",                                # general
    "/dev/mali", "/dev/mali0", "/dev/umplock", # mali
    "/dev/nvidiactl", "/dev/nvidia-modeset",   # nvidia
    "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools" # nvidia OpenCl/CUDA
  ]

  for mount in mounts:
    if deviceExists(mount):
      call.addMount("--dev-bind", mount)

  for i in 0..20:
    let device = &"/dev/nvidia{i}"

    if deviceExists(device):
      call.addMount("--dev-bind", device)