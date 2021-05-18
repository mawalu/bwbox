import strformat
import lib/bwrap
import os

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

var call = BwrapCall()

call.addArg("--bind", sandboxFiles, getHomeDir())

for mount in ["/sys"]:
  call.addMount("--bind", mount)

for mount in ["/etc", "/var", "/usr", "/opt", homePath(".oh-my-zsh"), homePath(".zsh"), homePath(".zshrc")]:
  call.addMount("--ro-bind", mount)

call
  .addMount("--dev-bind", "/dev")
  .addArg("--dir", "/tmp")
  .addArg("--symlink", "usr/lib", "/lib")
  .addArg("--symlink", "usr/lib64", "/lib64")
  .addArg("--symlink", "usr/bin", "/bin")
  .addArg("--symlink", "usr/sbin", "/sbin")
  .addArg("--proc", "/proc")
  .addArg("--unshare-all")
  .addArg("--share-net")
  .addArg("--die-with-parent")
  .addArg("--hostname", name)
  .addArg("--chdir", getHomeDir())
  .addArg(command)
  .exec()

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