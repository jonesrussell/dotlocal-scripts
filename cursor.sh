#!/usr/bin/env sh

# Fetch the Windows username dynamically
WINDOWS_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')

# Ensure to use the dynamically retrieved username in VSCODE_PATH
VSCODE_PATH="/mnt/c/Users/${WINDOWS_USER}/AppData/Local/Programs/cursor/"

SERVER_BIN="${HOME}/.cursor-server/bin/"
COMMIT="$(ls -t1 $SERVER_BIN 2>/dev/null | head -n 1)"
APP_NAME="code"
QUALITY="stable"
NAME="Cursor"
SERVERDATAFOLDER=".cursor-server"
ELECTRON="$VSCODE_PATH/$NAME.exe"

if [ "$VSCODE_WSL_DEBUG_INFO" = true ]; then
  set -x
fi

IN_WSL=false
if [ -n "$WSL_DISTRO_NAME" ]; then
  IN_WSL=true
else
  WSL_BUILD=$(uname -r | sed -E 's/^[0-9.]+-([0-9]+)-Microsoft.*|.*/\1/')
  if [ -n "$WSL_BUILD" ] && [ "$WSL_BUILD" -ge 17063 ]; then
    IN_WSL=true
  else
    "$ELECTRON" "$@"
    exit $?
  fi
fi

if [ $IN_WSL = true ]; then
  export WSLENV="ELECTRON_RUN_AS_NODE/w:$WSLENV"
  CLI=$(wslpath -m "$VSCODE_PATH/resources/app/out/cli.js")

  WSL_EXT_ID="ms-vscode-remote.remote-wsl"
  ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" --ms-enable-electron-run-as-node --locate-extension $WSL_EXT_ID >/tmp/remote-wsl-loc.txt 2>/dev/null </dev/null
  WSL_EXT_WLOC=$(tail -n 1 /tmp/remote-wsl-loc.txt)
  WSL_CODE=$(wslpath -u "${WSL_EXT_WLOC%%[[:cntrl:]]}")/scripts/wslCode.sh

  MY_CLI_DIR_YO="$SERVER_BIN/$COMMIT/bin/remote-cli"
  if [ ! -d "$MY_CLI_DIR_YO/code" ]; then
    ln -s "$MY_CLI_DIR_YO/cursor" "$MY_CLI_DIR_YO/code"
  fi

  if [ -n "$WSL_EXT_WLOC" ]; then
    "$WSL_CODE" "$COMMIT" "$QUALITY" "$ELECTRON" "$APP_NAME" "$SERVERDATAFOLDER" "$@"
    exit $?
  fi
elif [ -x "$(command -v cygpath)" ]; then
  CLI=$(cygpath -m "$VSCODE_PATH/resources/app/out/cli.js")
else
  CLI="$VSCODE_PATH/resources/app/out/cli.js"
fi
ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" --ms-enable-electron-run-as-node "$@"
exit $?

