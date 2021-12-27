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
  let pid = getCurrentProcessId()

  for path in [
    getConfigDir().joinPath(APP_NAME),
    &"/usr/share/{APP_NAME}",
    parentDir(expandSymlink(&"/proc/{pid}/exe")).joinPath("configs")
  ]:
    let file = path.joinPath(profile)

    if fileExists(file):
      return file

  raise newException(IOError, "Profile not found")

proc getProfilePath*(args: Args): string =
  getProfilePath(args.getProfile())

proc getSandboxPath*(name: string): string =
  getDataDir()
    .joinPath(APP_NAME)
    .joinPath(name)

proc deviceExists(path: string): bool =
  var res: Stat
  return stat(path, res) >= 0 and S_ISCHR(res.st_mode)

proc mountDriFolder(call: var BwrapCall, path: string) =
  for file in walkPattern(&"{path}/*"):
    if dirExists(file):
      mountDriFolder(call, file)
    elif deviceExists(file):
      call.addMount("--dev-bind", file)
    #else:
    #  call.addMount("--ro-bin", file)

# https://github.com/flatpak/flatpak/blob/1bdbb80ac57df437e46fce2cdd63e4ff7704718b/common/flatpak-run.c#L1496
proc enableDri*(call: var BwrapCall) =
  const folder = "/dev/dri"
  const mounts = [
    folder,                                    # general
    "/dev/mali", "/dev/mali0", "/dev/umplock", # mali
    "/dev/nvidiactl", "/dev/nvidia-modeset",   # nvidia
    "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools" # nvidia OpenCl/CUDA
  ]

  if dirExists(folder):
    mountDriFolder(call, folder)

  for mount in mounts:
    if deviceExists(mount) or dirExists(mount):
      call.addMount("--dev-bind", mount)

  for i in 0..20:
    let device = &"/dev/nvidia{i}"

    if deviceExists(device):
      call.addMount("--dev-bind", device)