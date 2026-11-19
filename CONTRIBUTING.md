# Contributing

Thanks for helping with the SemiTO-V verification environment. This repo is
fully open source (Apache-2.0). Small, focused pull requests are welcome.

## How we work

1. Open an issue (or comment on an existing one) if you are changing tools or
   the image in a non-trivial way.
2. Branch from `main`, make your change, and open a pull request.
3. CI must stay green: the smoke workflow runs `check-tools` and the hello-world
   simulation + formal checks inside the published image.

## Changing a tool version

Pin every version in `docker/Dockerfile` or `docker/requirements.txt` (see the
table in the README). After changing pins:

1. Rebuild and smoke-test locally, or wait for the *Build verification image*
   workflow after merge.
2. Teammates refresh with **Dev Containers: Rebuild Container**.

## Local image build (optional)

```bash
docker build -t semitov-verif-env:local docker
# or multi-arch publish (maintainers):
# docker buildx build --platform linux/amd64,linux/arm64 \
#   -t ghcr.io/semitov/semitov-verif-env:latest --push docker
```

## Code style

- Keep scripts POSIX/`bash` with `LF` line endings (enforced by `.gitattributes`).
- Prefer pinned, reproducible deps over “latest”.
