# CM032 Images

[![python-clawpack](https://github.com/CM032/images/actions/workflows/python-clawpack.yml/badge.svg)](https://github.com/CM032/images/actions/workflows/python-clawpack.yml)
[![python-py-pde](https://github.com/CM032/images/actions/workflows/python-py-pde.yml/badge.svg)](https://github.com/CM032/images/actions/workflows/python-py-pde.yml)
[![python-fenics-dolfinx](https://github.com/CM032/images/actions/workflows/python-fenics-dolfinx.yml/badge.svg)](https://github.com/CM032/images/actions/workflows/python-fenics-dolfinx.yml)
[![deal-ii](https://github.com/CM032/images/actions/workflows/deal-ii.yml/badge.svg)](https://github.com/CM032/images/actions/workflows/deal-ii.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)

This repository contains **Docker images** for scientific computing and development environments, built on **Arch Linux**. Images are automatically built and published to the **GitHub Container Registry (GHCR)** via GitHub Actions.

All images share a common foundation:

| Attribute             | Details                                    |
| --------------------- | ------------------------------------------ |
| **Base image**        | `archlinux:base-devel`                     |
| **Platform**          | `linux/amd64`                              |
| **Default user**      | `vscode` (UID/GID 1000, passwordless sudo) |
| **Working directory** | `/workspaces`                              |
| **Exposed port**      | `8888/tcp` (JupyterLab)                    |
| **Maintenance**       | [Carlos Aznarán](mailto:caznaranl@uni.pe)  |

> For multi-stage build architecture, environment variables, build arguments, layer caching, and extending images, see the [technical README](docker/README.md).

## Available Images

| Image                                           | Registry                                            | Focus                                           |
| ----------------------------------------------- | --------------------------------------------------- | ----------------------------------------------- |
| [python-clawpack](#python-clawpack)             | `ghcr.io/cm032/images/python-clawpack:latest`       | Hyperbolic PDEs with Clawpack                   |
| [python-py-pde](#python-py-pde)                 | `ghcr.io/cm032/images/python-py-pde:latest`         | PDEs on regular grids with py-pde               |
| [python-fenics-dolfinx](#python-fenics-dolfinx) | `ghcr.io/cm032/images/python-fenics-dolfinx:latest` | FEM workflows with meshing and 3D visualization |
| [deal-ii](#deal-ii)                             | `ghcr.io/cm032/images/deal-ii:latest`               | Finite elements with deal.II                    |

### python-clawpack

A pre-configured environment for **hyperbolic PDEs** with [Clawpack](https://www.clawpack.org/) and a rich **JupyterLab** ecosystem.

**Included software**

- **Clawpack** — hyperbolic PDE solvers
- **Octave kernel** for Jupyter (`jupyter-octave_kernel`)
- **JupyterLab** extensions: `jupyterlab-rise`, `jupyterlab-pytutor`, `jupyter-nbgrader`, `jupyterlab-variableinspector`, `jupyter-server-terminals`
- **Scientific Python**: `pandas`, `ipympl`, `matplotlib` (retina), `jupyterlab-widgets`, `numpy`, `scipy`, `pytest`
- **Development tools**: `black`, `isort`, `pyupgrade`, `nbqa`, `ffmpeg`, `threadpoolctl`, `bat`, `git`
- **Font**: Intel One Mono (OTF)

```bash
docker pull ghcr.io/cm032/images/python-clawpack:latest

docker run --rm -it \
  -p 8888:8888 \
  -v "$(pwd):/workspaces" \
  ghcr.io/cm032/images/python-clawpack:latest \
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### python-py-pde

An environment for solving **partial differential equations on regular grids** with [py-pde](https://github.com/zwicker-group/py-pde).

**Included software**

- **py-pde** — finite-difference PDE framework
- **JupyterLab** extensions: `jupyterlab-rise`, `jupyterlab-pytutor`, `jupyter-nbgrader`, `jupyterlab-variableinspector`, `jupyter-server-terminals`
- **Scientific Python**: `pandas`, `ipympl`, `matplotlib` (retina), `jupyterlab-widgets`, `numpy-mkl`, `scipy-mkl`, `pytest`
- **Development tools**: `black`, `isort`, `pyupgrade`, `nbqa`, `ffmpeg`, `threadpoolctl`, `bat`, `git`
- **Font**: Intel One Mono (OTF)

```bash
docker pull ghcr.io/cm032/images/python-py-pde:latest

docker run --rm -it \
  -p 8888:8888 \
  -v "$(pwd):/workspaces" \
  ghcr.io/cm032/images/python-py-pde:latest \
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### python-fenics-dolfinx

A **finite-element workflow** image with mesh generation, headless 3D rendering, and collaborative JupyterLab — oriented toward FEniCS/dolfinx-style simulations.

**Included software**

- **Gmsh** — mesh generation
- **PyVista** + **Trame** — interactive 3D visualization in Jupyter (off-screen via Xvfb)
- **Jupyter collaboration** — real-time notebook editing
- **Scientific Python**: `pandas`, `ipympl`, `numpy-mkl`, `scipy-mkl`, `jupyterlab-widgets`
- **JupyterLab** extensions and development tools (same core set as the other images)
- **PETSc** environment variables preconfigured

```bash
docker pull ghcr.io/cm032/images/python-fenics-dolfinx:latest

docker run --rm -it \
  -p 8888:8888 \
  -v "$(pwd):/workspaces" \
  ghcr.io/cm032/images/python-fenics-dolfinx:latest \
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### deal-ii

An environment for **finite-element computations** with the [deal.II](https://www.dealii.org/) C++ library, plus the same meshing and visualization stack as `python-fenics-dolfinx`.

**Included software**

- **deal.II** — adaptive finite-element library
- **Gmsh**, **PyVista**, **Trame** — meshing and 3D Jupyter visualization
- **Jupyter collaboration**
- **Scientific Python**: `pandas`, `ipympl`, `numpy-mkl`, `scipy-mkl`, `jupyterlab-widgets`
- **JupyterLab** extensions and development tools (same core set as the other images)

```bash
docker pull ghcr.io/cm032/images/deal-ii:latest

docker run --rm -it \
  -p 8888:8888 \
  -v "$(pwd):/workspaces" \
  ghcr.io/cm032/images/deal-ii:latest \
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

## CI/CD Pipeline

Each image has its own GitHub Actions workflow under `.github/workflows/`:

| Workflow                    | Dockerfile                                | GHCR tag                                            |
| --------------------------- | ----------------------------------------- | --------------------------------------------------- |
| `python-clawpack.yml`       | `docker/python-clawpack.Dockerfile`       | `ghcr.io/cm032/images/python-clawpack:latest`       |
| `python-py-pde.yml`         | `docker/python-py-pde.Dockerfile`         | `ghcr.io/cm032/images/python-py-pde:latest`         |
| `python-fenics-dolfinx.yml` | `docker/python-fenics-dolfinx.Dockerfile` | `ghcr.io/cm032/images/python-fenics-dolfinx:latest` |
| `deal-ii.yml`               | `docker/deal-ii.Dockerfile`               | `ghcr.io/cm032/images/deal-ii:latest`               |

**Triggers** (per workflow):

- Push to `main` modifying the corresponding Dockerfile
- Pull requests targeting `main`
- Scheduled rebuild on the 1st day of each month at 02:00 UTC

**Steps**:

1. Maximize GitHub runner disk space
2. Sparse clone the repository (only the `docker/` directory)
3. Set up Docker Buildx with per-image layer caching
4. Build and push the image to GHCR
5. Run a container vulnerability scan (critical severity threshold)
6. Prune untagged images (keeping latest 2)

### Dependabot

[Dependabot](https://docs.github.com/code-security/dependabot) is configured to automatically update GitHub Actions dependencies on a **weekly** basis.

## Repository Structure

```
.
├── docker/
│   ├── python-clawpack.Dockerfile
│   ├── python-py-pde.Dockerfile
│   ├── python-fenics-dolfinx.Dockerfile
│   ├── deal-ii.Dockerfile
│   └── README.md                    # Technical documentation
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── python-clawpack.yml
│       ├── python-py-pde.yml
│       ├── python-fenics-dolfinx.yml
│       └── deal-ii.yml
├── .dockerignore
├── .gitignore
├── LICENSE
└── README.md
```

## Build Locally

Replace `<image>` and `<dockerfile>` with the target image name:

```bash
git clone https://github.com/CM032/images.git
cd images

docker build \
  -t ghcr.io/cm032/images/<image>:latest \
  -f docker/<dockerfile> \
  --no-cache \
  .
```

Examples:

```bash
# python-clawpack
docker build -t ghcr.io/cm032/images/python-clawpack:latest \
  -f docker/python-clawpack.Dockerfile .

# deal-ii
docker build -t ghcr.io/cm032/images/deal-ii:latest \
  -f docker/deal-ii.Dockerfile .
```

> **Note**: Building these images involves compiling packages from the AUR (Arch User Repository), which may take a significant amount of time.

## License

This project is licensed under the **GNU General Public License v2.0**. See the [LICENSE](LICENSE) file for details.

## Author

- **Carlos Aznarán** – [caznaranl@uni.pe](mailto:caznaranl@uni.pe)

---

*Built with ❤️ for the scientific computing community.*
