# SemiTO-V verification environment

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Open-source Docker / Dev Container environment for the **SemiTO-V** student
team: the same verification tools on every laptop and in CI.

Image (public): [`ghcr.io/semitov/semitov-verif-env:latest`](https://ghcr.io/semitov/semitov-verif-env:latest)

| Included | Role |
| --- | --- |
| Verilator, Yosys, SymbiYosys, SMT solvers | Via [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) |
| cocotb, pyuvm, cocotb-coverage | Python verification (pinned in `docker/requirements.txt`) |
| Spike (lowRISC cosim), riscv-tests, riscv-formal | ISA sim, tests, formal checkers |
| RISC-V GCC | Bare-metal RV32 programs (`gcc-riscv64-unknown-elf`) |

First-day guide: **[docs/SETUP.md](docs/SETUP.md)**.

## Quick start

1. Install [Git](https://git-scm.com/), [Docker](https://docs.docker.com/get-docker/), and [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.com/) with the **Dev Containers** extension.
2. Clone this repository (on Windows: clone **inside WSL**, not on `C:\`).
3. Open the folder → **Dev Containers: Reopen in Container**.
4. Wait for the image pull (~1.3 GB download; keep ~15 GB free). Then:

```bash
check-tools
make -C tests/hello
make -C tests/hello WAVES=1
make -C tests/hello formal
spike --isa=rv32i $RISCV_TESTS/isa/rv32ui-p-add && echo "Spike OK"
```

No GHCR login is required while the package stays public.

Without an IDE: `scripts/devshell.sh` or `scripts/devshell.sh make -C tests/hello`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `docker/` | Dockerfile, Python pins, `check-tools`, `tap-up` |
| `.devcontainer/` | Dev Container config (pulls the GHCR image) |
| `.github/workflows/` | Image publish + CI smoke tests |
| `tests/hello/` | Hello-world sim, waves, and formal check |
| `scripts/devshell.sh` | Container shell without VS Code / Cursor |
| `docs/SETUP.md` | Full onboarding and troubleshooting |

## Updating tools

Every version is pinned:

| Tool | Pin location |
| --- | --- |
| Verilator, Yosys, SymbiYosys, solvers | `OSS_CAD_SUITE_DATE` in `docker/Dockerfile` |
| Spike | `SPIKE_COMMIT` (lowRISC `ibex_cosim`) |
| riscv-formal / riscv-tests | Their `*_COMMIT` ARGs in the Dockerfile |
| Python packages | `docker/requirements.txt` |
| Base OS / RISC-V GCC | `ubuntu:24.04` + distro package |

Change pins on a branch, open a PR, merge when CI is green. The *Build verification image* workflow publishes a new multi-arch image. Teammates refresh with **Dev Containers: Rebuild Container**.

## Publishing the image

- **Already published** (manual buildx) as `ghcr.io/semitov/semitov-verif-env:latest` (amd64 + arm64).
- Pushes that touch `docker/` (or a manual workflow run) rebuild via `.github/workflows/image.yml` and push to `ghcr.io/semitov/semitov-verif-env`.

Keep the GHCR package **Public** so the team can pull without tokens.

## License

This project is licensed under the [Apache License 2.0](LICENSE).

Third-party tools inside the image (OSS CAD Suite, Spike, etc.) keep their own licenses; this repository’s license covers the Dockerfiles, scripts, tests, and docs authored here.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and pull requests from the team (and the wider community) are welcome.
