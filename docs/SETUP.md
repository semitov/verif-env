# First-day setup: SemiTO-V verification environment

Every member works inside the same Linux container, with the same tool
versions as CI. You install a few things on your laptop; everything else
(Verilator, cocotb, pyuvm, SymbiYosys, riscv-formal, Spike, the RISC-V
compiler) is already in the container.

You do **not** need to clone this repository for day-to-day verification work.
Copy [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json)
into the project repo you are working on, then reopen that project in the
container. The first image download is about 1.3 GB (~5 GB unpacked); keep at
least 15 GB free.

## 1. Install

Everyone: [Git](https://git-scm.com/), [Docker](https://docs.docker.com/get-docker/),
and [VS Code](https://code.visualstudio.com/) with the **Dev Containers** extension
(`ms-vscode-remote.remote-containers`).

Then, depending on your OS:

| OS | Install | Watch out for |
| --- | --- | --- |
| Linux | [Docker Engine](https://docs.docker.com/engine/install/), then `sudo usermod -aG docker $USER` and log out and back in | Nothing special |
| Windows 10/11 | **WSL2 first** (`wsl --install` in an admin PowerShell, then reboot), then [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) with the WSL2 backend; enable your Ubuntu distro under Docker Desktop → Settings → Resources → WSL integration. In VS Code, also install the **WSL** extension | Clone and open project repos **inside WSL** (for example `~/my-project`), not on `C:\`. Work on `C:\` is several times slower. Always start VS Code from the WSL terminal (`code .`) **before** **Reopen in Container** |
| macOS | [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) | Apple Silicon is fine: the image has a native arm64 version |

Give Docker at least 4 CPUs and 8 GB of memory (Docker Desktop → Settings → Resources).

## 2. Log in to GHCR (consumer repos)

From the project repo where you copied `.devcontainer/devcontainer.json`, Docker
must be able to pull `ghcr.io/semitov/semitov-verif-env:latest`.

1. On GitHub: profile picture → **Settings** → **Developer settings** →
   **Personal access tokens** → **Tokens (classic)** →
   **Generate new token (classic)**.
2. Name the token, set an expiry, enable **`read:packages`**, generate it, and
   copy the value (shown only once). Do **not** commit it.
3. Save the PAT somewhere durable — a password manager,
   [GitHub CLI](https://cli.github.com/) (`gh auth login`), or a Git credential
   helper:

```bash
# macOS
git config --global credential.helper osxkeychain

# Windows (Git Credential Manager; run inside WSL if that is where you work)
git config --global credential.helper manager

# Linux (plaintext file in your home directory — prefer a password manager if you can)
git config --global credential.helper store
# Or short-lived cache only:
# git config --global credential.helper 'cache --timeout=86400'
```

```bash
printf "protocol=https\nhost=ghcr.io\nusername=<YOUR_GITHUB_USERNAME>\npassword=<YOUR_PAT>\n\n" \
  | git credential approve
```

Or with GitHub CLI instead of a classic PAT helper:

```bash
gh auth login
# choose GitHub.com → HTTPS → authenticate (browser or token)
```

4. Log Docker into GHCR (on Windows: run this inside WSL):

```bash
# With the PAT (from your password manager / credential helper):
echo "<YOUR_PAT>" | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin

# Or if you used gh auth login:
echo "$(gh auth token)" | docker login ghcr.io -u "$(gh api user -q .login)" --password-stdin
```

You only need the Docker login once per machine (until the token expires or you
`docker logout ghcr.io`). If the GHCR package is **Public**, anonymous pulls
also work and you can skip this section.

## 3. Open your project in the container

1. Add `.devcontainer/devcontainer.json` from this repository to your project
   (or confirm the project already has it).
2. Open the project folder in VS Code.
   - **Windows:** open it from the WSL terminal with `code .`.
   - **macOS / Linux:** open the folder as usual.
3. Command palette → **Dev Containers: Reopen in Container**.
4. The first time, Docker downloads
   `ghcr.io/semitov/semitov-verif-env:latest` (~1.3 GB).

From then on, every terminal in the IDE is a terminal inside the container.
CI already validates the image when it is published, so you do not need to
re-run the hello-world suite to start working.
## 4. Testing the tools (optional)

Clone **this** repository only when you are developing or smoke-testing the
environment itself:

```bash
git clone https://github.com/semitov/semitov-verif-env.git
cd semitov-verif-env
```

On Windows, clone **inside WSL**, then `code .` from that terminal.
**Dev Containers: Reopen in Container**, then:

```bash
check-tools                    # every tool and its version: ends with "All tools found."
make -C tests/hello            # simulation test: ends with "TESTS=1 PASS=1 FAIL=0"
make -C tests/hello WAVES=1    # same, and writes the waveform tests/hello/dump.fst
make -C tests/hello formal     # formal check: ends with "DONE (PASS, rc=0)"
spike --isa=rv32i $RISCV_TESTS/isa/rv32ui-p-add && echo "Spike OK"
```

Open the waveform: in the Explorer, click `tests/hello/dump.fst`. It opens in
VaporView, the waveform viewer installed in the container.

If anything fails, post the output of `check-tools` in the team channel.

## Without VS Code

From a clone of this repository:

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
machine, so traffic scripts must also run inside the container. Your project's
`devcontainer.json` needs the TAP `runArgs` from this repository's config.

## Updating

When the image changes (a tool version bump), CI publishes a new one. To get it:
command palette → **Dev Containers: Rebuild Container**.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `denied` or `unauthorized` when pulling the image | Create a classic PAT with `read:packages` and run `echo "<YOUR_PAT>" \| docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin` (see step 2), or ask a maintainer to make the package **Public** |
| `not found` when pulling the image | The image was not published yet, or the tag is wrong. Ask a maintainer to run **Build verification image** and confirm the package is public |
| `/usr/bin/env: 'bash\r': No such file or directory` | The repository was checked out with Windows line endings. In WSL: `git config --global core.autocrlf false`, then clone again |
| Everything is very slow on Windows | The repository is on `C:\`. Clone it inside WSL instead (see step 1) |
| Very slow on a Mac with Apple Silicon | You are running the x86 image under emulation. In a container terminal, `uname -m` should print `aarch64` |
| `/dev/net/tun not available` in `check-tools` | Only matters for Step 6. Open the folder with Dev Containers (it adds the right flags), not a plain `docker run` |
| Docker runs out of disk space | `docker system prune` removes old images and build cache |
