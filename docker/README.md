# Technical Documentation — CM032 Docker Images

## Overview

This document describes the internal design, build pipeline, and runtime configuration of the **CM032 Docker images**. All images are built on **Arch Linux** and provide JupyterLab-based scientific computing environments.

| Image                 | Registry                                            | Dockerfile                         |
| --------------------- | --------------------------------------------------- | ---------------------------------- |
| python-clawpack       | `ghcr.io/cm032/images/python-clawpack:latest`       | `python-clawpack.Dockerfile`       |
| python-py-pde         | `ghcr.io/cm032/images/python-py-pde:latest`         | `python-py-pde.Dockerfile`         |
| python-fenics-dolfinx | `ghcr.io/cm032/images/python-fenics-dolfinx:latest` | `python-fenics-dolfinx.Dockerfile` |
| deal-ii               | `ghcr.io/cm032/images/deal-ii:latest`               | `deal-ii.Dockerfile`               |

**Maintainer**: [Carlos Aznarán](mailto:caznaranl@uni.pe)

---

## Shared Architecture: Multi-Stage Build

Every Dockerfile implements a **two-stage build** to minimize the final image footprint while keeping compile-time dependencies (AUR, base-devel, etc.) in the builder stage.

```
┌──────────────────────────────────────────────────┐
│           STAGE 1: build (FROM aur image)        │
│  - Builds AUR_PACKAGES (image-specific)          │
│  - Builds EXTRA_AUR_PACKAGES (shared Jupyter)    │
│  - Output: *.pkg.tar.zst artifacts + build logs   │
└──────────────┬───────────────────────────────────┘
               │ COPY --from=build
               ▼
┌──────────────────────────────────────────────────┐
│           STAGE 2: final (FROM archlinux:base-devel)│
│  - Creates non-root `vscode` user                 │
│  - Adds arch4edu repository                       │
│  - Installs runtime PACKAGES (via pacman)         │
│  - Installs prebuilt .pkg.tar.zst from stage 1    │
│  - Configures IPython, locale, shell              │
└──────────────────────────────────────────────────┘
```

### Stage 1 — Builder

```dockerfile
FROM ghcr.io/cpp-review-dune/introductory-review/aur AS build
```

This stage uses a pre-configured AUR builder image to compile packages not available in the official Arch Linux repositories.

#### Shared AUR Packages (`EXTRA_AUR_PACKAGES`)

Installed in all images:

| Package                               | Purpose                           |
| ------------------------------------- | --------------------------------- |
| `jupyter-nbgrader`                    | Notebook grading                  |
| `jupyterlab-rise`                     | Reveal.js slideshows              |
| `nbqa`                                | Run QA tools on Jupyter notebooks |
| `otf-intel-one-mono`                  | Intel One Mono font               |
| `python-jupyterlab-variableinspector` | Variable inspection               |
| `pyupgrade`                           | Modern Python syntax migration    |

#### Image-Specific AUR Packages (`AUR_PACKAGES`)

| Image                 | `AUR_PACKAGES`                           |
| --------------------- | ---------------------------------------- |
| python-clawpack       | `python-clawpack`                        |
| python-py-pde         | `python-py-pde`, `jupyter-octave_kernel` |
| python-fenics-dolfinx | *(none — only `EXTRA_AUR_PACKAGES`)*     |
| deal-ii               | *(none — only `EXTRA_AUR_PACKAGES`)*     |

The build process:

1. Syncs the AUR via `yay`
2. Builds and installs `AUR_PACKAGES` and `EXTRA_AUR_PACKAGES` with `--nocheck` (skips tests to reduce build time)
3. Logs all build output to timestamped files in `/tmp/`

### Stage 2 — Final Image

A clean `archlinux:base-devel` image that receives only the pre-compiled artifacts from Stage 1.

#### Shared Runtime Packages

All images include:

| Package                                | Purpose                                          |
| -------------------------------------- | ------------------------------------------------ |
| `bat`                                  | Syntax-highlighted file viewer                   |
| `blas-openblas`                        | Optimized BLAS/LAPACK                            |
| `ffmpeg`                               | Multimedia processing                            |
| `git`                                  | Version control                                  |
| `jupyterlab-widgets`                   | Interactive Jupyter widgets                      |
| `less`                                 | Pager                                            |
| `python-black`                         | Code formatter                                   |
| `python-isort`                         | Import sorter                                    |
| `python-ipympl`                        | Interactive Matplotlib plots                     |
| `python-jupyter-server-terminals`      | Terminal access in JupyterLab                    |
| `python-numpy-mkl`                     | NumPy with Intel MKL                             |
| `python-pandas`                        | Data analysis                                    |
| `python-scipy-mkl`                     | SciPy with Intel MKL                             |
| `python-threadpoolctl`                 | Threadpool control for BLAS                      |
| *(prebuilt .pkg.tar.zst from Stage 1)* | Jupyter extensions + image-specific AUR packages |

#### Image-Specific Runtime Packages

| Image                 | Additional packages                                                                                                                                               |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| python-clawpack       | `python-pytest`                                                                                                                                                   |
| python-py-pde         | `python-pytest`                                                                                                                                                   |
| python-fenics-dolfinx | `gmsh`, `python-pyvista`, `python-trame`, `python-trame-vtk`, `python-trame-vuetify`, `jupyter-collaboration`, `xorg-fonts-100dpi`, `xorg-server-xvfb`            |
| deal-ii               | `deal-ii`, `gmsh`, `python-pyvista`, `python-trame`, `python-trame-vtk`, `python-trame-vuetify`, `jupyter-collaboration`, `xorg-fonts-100dpi`, `xorg-server-xvfb` |

> **Note**: `python-fenics-dolfinx.Dockerfile` and `deal-ii.Dockerfile` define a `VTK_PACKAGES` ARG that is not currently referenced in the install step.

#### arch4edu Repository

All final-stage images add the [arch4edu](https://gitlab.com/dune-archiso/dune-archiso) repository via:

```bash
curl -s https://gitlab.com/dune-archiso/dune-archiso.gitlab.io/-/raw/main/templates/add_arch4edu.sh | bash
```

This provides access to educational and scientific packages not in the official Arch repos.

---

## Environment Configuration

### Pacman Optimization

Multiple `sed` modifications tune `pacman.conf` for faster package management:

| Change                                            | Effect                                          |
| ------------------------------------------------- | ----------------------------------------------- |
| `Color` enabled                                   | Colored output                                  |
| `DisableSandbox`                                  | Avoids sandbox issues in container environments |
| `DownloadUser`                                    | Allows pacman as root without sandbox           |
| `ILoveCandy`                                      | Progress bar eye candy                          |
| `ParallelDownloads = 30`                          | Downloads up to 30 packages concurrently        |
| `VerbosePkgLists` disabled                        | Quieter output                                  |
| `/usr/share/doc/*` and `/usr/share/man/*` removed | Reduces image size                              |
| Multilib repository enabled                       | 32-bit library support                          |
| `MAKEFLAGS="-j$(nproc)"`                          | Parallel compilation                            |
| `BUILDDIR` enabled                                | Custom build directory in `makepkg.conf`        |

### User Setup

- **Username**: `vscode`
- **UID/GID**: `1000/1000` (configurable via build args)
- **Shell**: Bash with a customized prompt (`\u \w \$`)
- **Sudo**: Passwordless sudo configured via `/etc/sudoers.d/90-vscode`
- **Home directory**: `/home/vscode`
- **Timezone**: `America/Lima`

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

#### Shared

| Variable                         | Value | Purpose                                         |
| -------------------------------- | ----- | ----------------------------------------------- |
| `MKL_THREADING_LAYER`            | `gnu` | MKL threading compatibility                     |
| `PYDEVD_DISABLE_FILE_VALIDATION` | `1`   | Disables file validation in the Python debugger |

#### python-clawpack

Additionally, the Octave kernel is installed at build time:

```bash
python -m octave_kernel install --user
```

#### python-py-pde

| Variable     | Value            | Purpose                                          |
| ------------ | ---------------- | ------------------------------------------------ |
| `PYTHONPATH` | `$PETSC_DIR/lib` | Inherited reference (no PETSc package installed) |

#### python-fenics-dolfinx and deal-ii

| Variable                             | Value                                              | Purpose                                |
| ------------------------------------ | -------------------------------------------------- | -------------------------------------- |
| `PYTHONPATH`                         | `/usr/share/gmsh/api/python` then `$PETSC_DIR/lib` | Gmsh Python API, then PETSc            |
| `TRAME_DISABLE_V3_WARNING`           | `1`                                                | Suppress Trame v3 deprecation warnings |
| `DISPLAY`                            | `:99.0`                                            | Virtual display for headless rendering |
| `PYVISTA_OFF_SCREEN`                 | `true`                                             | Off-screen PyVista rendering           |
| `PYVISTA_TRAME_SERVER_PROXY_PREFIX`  | `/proxy/`                                          | Jupyter proxy prefix for Trame         |
| `PYVISTA_TRAME_SERVER_PROXY_ENABLED` | `True`                                             | Enable Trame proxy in Jupyter          |
| `PYVISTA_JUPYTER_BACKEND`            | `trame`                                            | Use Trame as PyVista Jupyter backend   |
| `PETSC_DIR`                          | `/opt/petsc/linux-c-opt`                           | PETSc path reference                   |

---

## Runtime Configuration

### Exposed Ports

| Port       | Service                  |
| ---------- | ------------------------ |
| `8888/tcp` | JupyterLab web interface |

### Volumes

| Mount Point   | Recommendation                             |
| ------------- | ------------------------------------------ |
| `/workspaces` | Working directory; mount your project here |

### Default Command

Images have no default `CMD` or `ENTRYPOINT` — provide a command at runtime, e.g.:

```bash
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### Docker Labels

Each image sets maintainer, name, description, URL, VCS URL, vendor, and version labels. See the corresponding Dockerfile for exact values.

---

## Build Process

### Local Build

```bash
git clone https://github.com/CM032/images.git
cd images

docker build \
  -t ghcr.io/cm032/images/<image>:latest \
  -f docker/<dockerfile> \
  --no-cache \
  .
```

> **Note**: Building these images involves compiling packages from the AUR, which may take a significant amount of time.

### Build Arguments

| Argument   | Default  | Description        |
| ---------- | -------- | ------------------ |
| `USERNAME` | `vscode` | Non-root user name |
| `USER_UID` | `1000`   | User UID           |
| `USER_GID` | `1000`   | User GID           |

### Layer Caching Strategy

Each CI workflow uses Docker Buildx with a dedicated local cache directory:

| Image                 | Cache path                                 | Cache key prefix                                 |
| --------------------- | ------------------------------------------ | ------------------------------------------------ |
| python-clawpack       | `/tmp/.buildx-python-clawpack-cache`       | `${{ runner.os }}-buildx-python-clawpack-`       |
| python-py-pde         | `/tmp/.buildx-python-py-pde-cache`         | `${{ runner.os }}-buildx-python-py-pde-`         |
| python-fenics-dolfinx | `/tmp/.buildx-python-fenics-dolfinx-cache` | `${{ runner.os }}-buildx-python-fenics-dolfinx-` |
| deal-ii               | `/tmp/.buildx-deal-ii-cache`               | `${{ runner.os }}-buildx-deal-ii-`               |

- **Cache mode**: `max` (exports all layers, not just the final)
- **Restore keys**: Falls back to the latest cache for the same image if no exact SHA match exists

---

## CI/CD Pipeline

Each image has a dedicated workflow in `.github/workflows/`.

### Trigger Events

| Event          | Condition                                                  |
| -------------- | ---------------------------------------------------------- |
| `push`         | On `main` branch when the corresponding Dockerfile changes |
| `pull_request` | Targeting `main` branch                                    |
| `schedule`     | 1st day of every month at 02:00 UTC (`0 2 1 * *`)          |

### Pipeline Steps

1. **Maximize disk space** — `justinthelaw/maximize-github-runner-space@main` with `cleanup-profile: max`
2. **Sparse clone** — Clones only the `docker/` directory
3. **Docker Buildx setup** — Enables builds with per-image caching
4. **Build and push** — Uploads to the corresponding `ghcr.io/cm032/images/<image>:latest` tag
5. **Vulnerability scan** — `crazy-max/ghaction-container-scan@master` with `severity_threshold: CRITICAL`
6. **Prune untagged images** — `carlosal1015/ghcr-delete-image-action@main`, keeps latest 2 untagged versions

### Required Secrets

| Secret         | Purpose                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| `GITHUB_TOKEN` | Authentication for GHCR push (provided automatically by GitHub Actions)        |
| `PAT`          | Personal Access Token with `delete:packages` scope for pruning untagged images |

---

## Extending an Image

### Adding Runtime Packages

Modify the `PACKAGES` ARG in the target Dockerfile:

```dockerfile
ARG PACKAGES="\
  bat \
  ffmpeg \
  python-numpy-mkl \
  python-scipy \        # added
  "
```

### Adding AUR Packages

Add package names to `AUR_PACKAGES` or `EXTRA_AUR_PACKAGES` in Stage 1.

> AUR builds are slow. Only add packages that are not available in the official Arch repositories or arch4edu.

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

| Constraint                          | Reason                                                                             |
| ----------------------------------- | ---------------------------------------------------------------------------------- |
| `--nocheck` during AUR build        | Tests are skipped to reduce build time; validate package functionality separately  |
| Single architecture (`linux/amd64`) | Arch Linux primarily targets x86_64; ARM builds are not currently supported        |
| Intel One Mono font only            | Font choice is tied to the IPython profile; override via `ipython_config.py`       |
| Large image sizes                   | Intel oneAPI, PETSc, deal.II, and the Jupyter ecosystem add significant disk usage |
| `VTK_PACKAGES` unused               | Defined in `python-fenics-dolfinx` and `deal-ii` Dockerfiles but not installed     |

---

*This document is intended for maintainers and advanced users. For a quick-start guide and user-friendly overview, see the [root-level README](../README.md).*
