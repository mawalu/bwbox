import strformat
import sequtils
import posix
import os

type BwrapCall = object
  args: seq[string]

proc addArg(call: var BwrapCall, args: varargs[string]) =
  for arg in args:
    call.args.add(arg)

proc addMount(call: var BwrapCall, mType: string, path: string) =
  addArg(call, mType, path, path)

proc exec(call: var BwrapCall) =
  discard execv("/usr/bin/bwrap", allocCStringArray(@["bwrap"].concat(call.args)))

proc homePath(p: string): string =
  joinPath(getHomeDir(), p)

let mode = splitPath(getAppFilename()).tail
let args = commandLineParams()
let argc = paramCount()

if argc == 0:
  echo &"Usage: {mode} <sandbox> [command]"
  quit(1)

let name = args[0]
var command = ""

if argc > 1:
  command = args[1]
else:
  command = getEnv("SHELL", "/bin/sh")

let sandboxPath = homePath(joinPath("sandboxes", name))
let sandboxFiles = joinPath(sandboxPath, "files")
let sandboxInfo = joinPath(sandboxPath, "info")

createDir(sandboxFiles)

var bwrap = BwrapCall()

for bMount in ["/sys"]:
  bwrap.addMount("--bind", bmount)

for roMount in ["/etc", "/var", "/usr", "/opt"]:
  bwrap.addMount("--ro-bind", roMount)

bwrap.addMount("--dev-bind", "/dev")
bwrap.addArg("--bind", sandboxFiles, getHomeDir())
bwrap.addArg("--dir", "/tmp")
bwrap.addArg("--symlink", "usr/lib", "/lib")
bwrap.addArg("--symlink", "usr/lib64", "/lib64")
bwrap.addArg("--symlink", "usr/bin", "/bin")
bwrap.addArg("--symlink", "usr/sbin", "/sbin")
bwrap.addArg("--proc", "/proc")
bwrap.addArg("--unshare-all")
bwrap.addArg("--share-net")
bwrap.addArg("--die-with-parent")
bwrap.addArg("--hostname", name)
bwrap.addArg("--chdir", getHomeDir())
bwrap.addArg(command)

bwrap.exec()

#[
(exec bwrap --bind $sandbox_files $HOME \
      ${cli_mode:+--bind $(pwd) $(pwd)} \
      ${cli_mode:+--bind $SSH_AUTH_SOCK $SSH_AUTH_SOCK} \
      ${gui_mode:+--bind /run/user/$(id -u)/pulse /run/user/$(id -u)/pulse} \
      ${gui_mode:+--bind /run/user/$(id -u)/wayland-0 /run/user/$(id -u)/wayland-0} \
      --bind /sys /sys \
      --ro-bind /etc /etc \
      --ro-bind /var /var \
      --ro-bind /usr /usr \
      --ro-bind /opt /opt \
      --ro-bind $HOME/.zshrc $HOME/.zshrc \
      --ro-bind $HOME/.zsh $HOME/.zsh \
      --ro-bind $HOME/.oh-my-zsh $HOME/.oh-my-zsh \
      --ro-bind $HOME/.ssh/known_hosts $HOME/.ssh/known_hosts \
      --dev-bind /dev /dev \
      --dir /tmp \
      --dir $HOME/.ssh \
      --symlink usr/lib /lib \
      --symlink usr/lib64 /lib64 \
      --symlink usr/bin /bin \
      --symlink usr/sbin /sbin \
      --proc /proc \
      --unshare-all \
      --share-net \
      --die-with-parent \
      --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
      --hostname "$name" \
      --chdir "$run_chdir" \
      --info-fd 11 \
      "$run_command") \
      11> "$sandbox_info"
]#