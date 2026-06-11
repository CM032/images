# Technical Documentation — `python-clawpack` Docker Image

## Overview

This document describes the internal design, build pipeline, and runtime configuration of the **python-clawpack** Docker image. The image is built on **Arch Linux** and provides a scientific computing environment centered around [Clawpack](https://www.clawpack.org/) and JupyterLab.

- **Base Image**: `archlinux:base-devel`
- **Platform**: `linux/amd64`
- **Registry**: `ghcr.io/cm032/images/python-clawpack:latest`
- **Maintainer**: [Carlos Aznarán](mailto:caznaranl@uni.pe)

---

## Image Architecture: Multi-Stage Build

The Dockerfile implements a **two-stage build** to minimize the final image footprint while keeping compile-time dependencies (AUR, base-devel, etc.) in the builder stage.

```
┌──────────────────────────────────────────────────┐
│           STAGE 1: build (FROM aur image)        │
│  - Installs OPT_PACKAGES (OpenBLAS, Intel oneAPI) │
│  - Builds AUR_PACKAGES (python-clawpack)          │
│  - Builds EXTRA_AUR_PACKAGES (jupyter extensions) │
│  - Output: *.pkg.tar.zst artifacts + build logs   │
└──────────────┬───────────────────────────────────┘
               │ COPY --from=build
               ▼
┌──────────────────────────────────────────────────┐
│           STAGE 2: final (FROM archlinux:base-devel)│
│  - Creates non-root `vscode` user                 │
│  - Installs runtime PACKAGES (via pacman)         │
│  - Installs prebuilt .pkg.tar.zst from stage 1    │
│  - Configures IPython, locale, shell              │
└──────────────────────────────────────────────────┘
```


### Stage 1 — Builder (`FROM ghcr.io/cpp-review-dune/introductory-review/aur AS build`)

This stage uses a pre-configured AUR builder image to compile all packages that are not available in the official Arch Linux repositories.

#### Package Groups

| Variable | Contents | Purpose |
|---|---|---|
| `OPT_PACKAGES` | `blas-openblas`, `intel-oneapi-basekit` | Optimized BLAS/LAPACK and Intel oneAPI math kernel library |
| `AUR_PACKAGES` | `python-clawpack` | Core Clawpack package for hyperbolic PDE solving |
| `EXTRA_AUR_PACKAGES` | `jupyter-nbgrader`, `jupyterlab-pytutor`, `jupyterlab-rise`, `otf-intel-one-mono`, `nbqa`, `python-jupyterlab-variableinspector`, `pyupgrade` | Jupyter ecosystem extensions, code quality tools, and the Intel One Mono font |

The build process:
1. Adds the `arch4edu` repository for additional packages
2. Installs `OPT_PACKAGES` from the official repos
3. Builds and installs `AUR_PACKAGES` and `EXTRA_AUR_PACKAGES` via `yay` with `--nocheck` (skips tests to reduce build time)
4. Logs all build output to timestamped files in `/tmp/`

### Stage 2 — Final Image (`FROM archlinux:base-devel`)

A clean Arch Linux base‑devel image that receives only the pre‑compiled artifacts from Stage 1.

#### Runtime Packages

| Package | Purpose |
|---|---|
| `ffmpeg` | Multimedia processing for notebook outputs |
| `jupyterlab-widgets` | Interactive Jupyter widgets |
| `python-black` | Code formatter |
| `python-isort` | Import sorter |
| `python-ipympl` | Interactive Matplotlib plots |
| `python-jupyter-server-terminals` | Terminal access in JupyterLab |
| `python-pandas` | Data analysis |
| `python-threadpoolctl` | Threadpool control for BLAS |
| *(prebuilt .pkg.tar.zst from Stage 1)* | Clawpack + Jupyter extensions |

---

## Environment Configuration

### Pacman Optimization

Multiple `sed` modifications tune `pacman.conf` for faster package management:

| Change | Effect |
|---|---|
| `Color` enabled | Colored output |
| `DisableSandbox` | Avoids sandbox issues in container environments |
| `DownloadUser` | Allows pacman as root without sandbox |
| `ILoveCandy` | Progress bar eye candy |
| `ParallelDownloads = 30` | Downloads up to 30 packages concurrently |
| `VerbosePkgLists` disabled | Quieter output |
| `/usr/share/doc/*` and `/usr/share/man/*` removed | Reduces image size |
| Multilib repository enabled | 32-bit library support |

### User Setup

- **Username**: `vscode`
- **UID/GID**: `1000/1000` (configurable via build args)
- **Shell**: Bash with a customized prompt (`\u \w \$`)
- **Sudo**: Passwordless sudo configured via `/etc/sudoers.d/90-vscode`
- **Home directory**: `/home/vscode`


### IPython Profile

Created at `~/.ipython/profile_default/ipython_config.py`:

```python
c.IPythonWidget.font_size = 11
c.IPythonWidget.font_family = 'Intel One Mono'
c.IPKernelApp.matplotlib = 'inline'
c.InlineBackend.figure_format = 'retina'
```

This ensures:
- Matplotlib renders inline in Jupyter notebooks
- High-DPI (retina) figure output
- Intel One Mono as the IDE font

### Environment Variables

| Variable | Value | Purpose |
|---|---|---|
| `PYDEVD_DISABLE_FILE_VALIDATION` | `1` | Disables file validation in the Python debugger for performance |

---

## Runtime Configuration

### Exposed Ports

| Port | Service |
|---|---|
| `8888/tcp` | JupyterLab web interface |

### Volumes

| Mount Point | Recommendation |
|---|---|
| `/workspaces` | Working directory; mount your project here |

### Default Command

The image starts with no default `CMD` or `ENTRYPOINT` — the user is expected to provide a command, e.g.:

```bash
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### Docker Labels

```dockerfile
LABEL maintainer="Carlos Aznarán <caznaranl@uni.pe>"
LABEL name="CM032"
LABEL description="Clawpack packages for CM032"
LABEL url="https://github.com/orgs/cm032/packages/container/package/images%2Fclawpack"
LABEL vcs-url="https://github.com/cm032/images"
LABEL vendor="Oromion Aznarán"
LABEL version="1.0"
```

---

## Build Process

### Local Build

```bash
git clone https://github.com/CM032/images.git
cd images

docker build \
  -t ghcr.io/cm032/images/python-clawpack:latest \
  -f docker/python-clawpack.Dockerfile \
  --no-cache \
  .
```

> **Note**: Building this image involves compiling packages from the AUR (Arch User Repository), which may take a significant amount of time.


### Build Arguments

| Argument | Default | Description |
|---|---|---|
| `USERNAME` | `vscode` | Non-root user name |
| `USER_UID` | `1000` | User UID |
| `USER_GID` | `1000` | User GID |

### Layer Caching Strategy

The CI workflow (`.github/workflows/python-clawpack.yml`) uses Docker Buildx with layer caching:

- **Cache backend**: Local filesystem at `/tmp/.buildx-cache`
- **Cache key**: `${{ runner.os }}-buildx-python-clawpack-${{ github.sha }}`
- **Restore keys**: Falls back to the latest cache for the same image if no exact SHA match exists
- **Cache mode**: `max` (exports all layers, not just the final)

---

## CI/CD Pipeline

The pipeline is defined in `.github/workflows/python-clawpack.yml`.

### Trigger Events

| Event | Condition |
|---|---|
| `push` | On `main` branch when `docker/python-clawpack.Dockerfile` changes |
| `pull_request` | Targeting `main` branch |
| `schedule` | 1st day of every month at 02:00 UTC (`0 2 1 * *`) |

### Pipeline Steps

1. **Maximize disk space** — Uses `justinthelaw/maximize-github-runner-space@main` with `cleanup-profile: max`
2. **Sparse clone** — Clones only the `docker/` directory to reduce checkout time
3. **Docker Buildx setup** — Enables multi-platform builds with caching
4. **Build and push** — Uploads to `ghcr.io/cm032/images/python-clawpack:latest`
5. **Vulnerability scan** — Uses `crazy-max/ghaction-container-scan@master` with `severity_threshold: CRITICAL`
6. **Prune untagged images** — Keeps only the latest 2 untagged images to maintain registry hygiene

### Required Secrets

| Secret | Purpose |
|---|---|
| `GITHUB_TOKEN` | Authentication for GHCR push (provided automatically by GitHub Actions) |
| `PAT` | Personal Access Token with `delete:packages` scope for pruning untagged images |


---

## Extending the Image

### Adding Runtime Packages

Modify the `PACKAGES` ARG in the Dockerfile:

```dockerfile
ARG PACKAGES="\
  ffmpeg \
  jupyterlab-widgets \
  python-black \
  python-isort \
  python-ipympl \
  python-jupyter-server-terminals \
  python-pandas \
  python-threadpoolctl \
  python-numpy \        # added
  python-scipy \        # added
  "
```

### Adding AUR Packages

Add new package names to `AUR_PACKAGES` or `EXTRA_AUR_PACKAGES` in Stage 1.

> ⚠️ AUR builds are slow. Only add packages that are not available in the official Arch repositories.

### Customizing the Non-Root User

Pass build args at build time:

```bash
docker build \
  --build-arg USERNAME=myuser \
  --build-arg USER_UID=2000 \
  --build-arg USER_GID=2000 \
  -t my-image \
  -f docker/python-clawpack.Dockerfile \
  .
```

---

## Dependabot Configuration

[Dependabot](https://docs.github.com/code-security/dependabot) is configured (`.github/dependabot.yml`) to automatically update GitHub Actions dependencies on a **weekly** basis. No Docker image rebuilds are triggered by Dependabot — only workflow file updates.

---

## Security

- The final image runs as a **non-root** user (`vscode`) by default
- Vulnerability scanning is enforced at the **CRITICAL** severity level during CI
- The builder stage is discarded — only pre-compiled packages are copied to the final image, reducing the attack surface
- Pacman sandbox is disabled to ensure compatibility with container environments

---

## Known Constraints

| Constraint | Reason |
|---|---|
| `--nocheck` during AUR build | Tests are skipped to reduce build time; validate package functionality separately |
| Single architecture (`linux/amd64`) | Arch Linux primarily targets x86_64; ARM builds are not currently supported |
| Intel One Mono font only | Font choice is tied to the IPython profile; override via `ipython_config.py` |
| ~5 GB+ image size | Result of including Intel oneAPI, Clawpack, and Jupyter ecosystem; consider using a slimmer variant if space is constrained |

---

*This document is intended for maintainers and advanced users. For a quick‑start guide and user‑friendly overview, see the [root-level README](../README.md).*
