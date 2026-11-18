# First-day setup: SemiTO-V verification environment

Every member works inside the same Linux container, with the same tool
versions as CI. You install a few things on your laptop; everything else
(Verilator, cocotb, pyuvm, SymbiYosys, riscv-formal, Spike, the RISC-V
compiler) is already in the container.

Goal: from a fresh laptop to a passing hello-world test in under an hour.
Most of that time is the first download of the image: about 1.3 GB, which
takes about 5 GB of disk once unpacked. Keep at least 15 GB free.

## 1. Install

Everyone: [Git](https://git-scm.com/), [Docker](https://docs.docker.com/get-docker/),
and either [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.com/)
with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`).

Then, depending on your OS:

| OS | Install | Watch out for |
| --- | --- | --- |
| Linux | [Docker Engine](https://docs.docker.com/engine/install/), then `sudo usermod -aG docker $USER` and log out and back in | Nothing special |
| Windows 10/11 | WSL2 (`wsl --install` in an admin PowerShell, then reboot), then [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) with the WSL2 backend; enable your Ubuntu distro under Docker Desktop → Settings → Resources → WSL integration. In VS Code / Cursor, also install the **WSL** extension | Clone the repository **inside WSL** (for example `~/semitov-verif-env`), not on `C:\`. Builds on `C:\` are several times slower |
| macOS | [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) | Apple Silicon is fine: the image has a native arm64 version |

Give Docker at least 4 CPUs and 8 GB of memory (Docker Desktop → Settings → Resources).

## 2. Open the repository in the container

1. Clone this repository. Windows: run this in the Ubuntu (WSL) terminal.
2. Open the folder in VS Code or Cursor. Windows: run `code .` or `cursor .` from the WSL terminal.
3. Choose **Reopen in Container**, or open the command palette (Ctrl/Cmd+Shift+P) and run **Dev Containers: Reopen in Container**.
4. The first time, Docker downloads the public image
   `ghcr.io/filippobrogi00/semitov-verif-env:latest`. When it is done, the
   terminal prints the tool check (`check-tools`), ending with **All tools found.**

From then on, every terminal in the IDE is a terminal inside the container.

## 3. Check that everything works

```bash
check-tools                    # every tool and its version: ends with "All tools found."
make -C tests/hello            # simulation test: ends with "TESTS=1 PASS=1 FAIL=0"
make -C tests/hello WAVES=1    # same, and writes the waveform tests/hello/dump.fst
make -C tests/hello formal     # formal check: ends with "DONE (PASS, rc=0)"
spike --isa=rv32i $RISCV_TESTS/isa/rv32ui-p-add && echo "Spike OK"
```

Open the waveform: in the Explorer, click `tests/hello/dump.fst`. It opens in
VaporView, the waveform viewer installed in the container.

If all of these pass, you are done. If anything fails, post the output of
`check-tools` in the team channel.

## Without VS Code / Cursor

```bash
scripts/devshell.sh                         # interactive shell
scripts/devshell.sh make -C tests/hello     # run a single command
```

## TAP networking (Step 6)

```bash
tap-up              # creates tap0 with address 192.168.1.100/24
ip addr show tap0
```

On Windows and macOS, the TAP interface lives inside Docker's Linux virtual
machine, so traffic scripts must also run inside the container.

## Updating

When the image changes (a tool version bump), CI publishes a new one. To get it:
command palette → **Dev Containers: Rebuild Container**.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `denied` or `unauthorized` when pulling the image | The package should be **Public**. If it was made private, ask a maintainer to open it again, or `docker login ghcr.io` with a token that has `read:packages` |
| `/usr/bin/env: 'bash\r': No such file or directory` | The repository was checked out with Windows line endings. In WSL: `git config --global core.autocrlf false`, then clone again |
| Everything is very slow on Windows | The repository is on `C:\`. Clone it inside WSL instead (see step 1) |
| Very slow on a Mac with Apple Silicon | You are running the x86 image under emulation. In a container terminal, `uname -m` should print `aarch64` |
| `/dev/net/tun not available` in `check-tools` | Only matters for Step 6. Open the folder with Dev Containers (it adds the right flags), not a plain `docker run` |
| Docker runs out of disk space | `docker system prune` removes old images and build cache |
