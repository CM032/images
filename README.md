# CM032 Images

[![Publish Docker image based on python-clawpack](https://github.com/CM032/images/actions/workflows/python-clawpack.yml/badge.svg)](https://github.com/CM032/images/actions/workflows/python-clawpack.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)

This repository contains **Docker images** for scientific computing and development environments, built on **Arch Linux**. The images are automatically built and published to the **GitHub Container Registry (GHCR)** via GitHub Actions.

## Available Images

### python-clawpack

| Attribute       | Details                                      |
|-----------------|----------------------------------------------|
| **Base Image**  | `archlinux:base-devel`                       |
| **Platform**    | `linux/amd64`                                |
| **Registry**    | `ghcr.io/cm032/images/python-clawpack:latest` |
| **Maintenance** | [Carlos Aznarán](mailto:caznaranl@uni.pe)    |

A pre-configured Docker image for **scientific computing** with [Clawpack](https://www.clawpack.org/) (a Python package for solving hyperbolic systems of partial differential equations) and a rich **JupyterLab** ecosystem.

#### Included Software

- **Clawpack** – solving hyperbolic PDEs
- **JupyterLab** with extensions:
  - `jupyterlab-rise` – Reveal.js slideshows
  - `jupyterlab-pytutor` – Python tutor integration
  - `jupyter-nbgrader` – notebook grading
  - `jupyterlab-variableinspector` – variable inspection
  - `jupyter-server-terminals` – terminal access
- **Scientific Python** libraries:
  - `pandas` – data analysis
  - `ipympl` – interactive matplotlib plots
  - `matplotlib` with retina display support
  - `jupyterlab-widgets` – interactive widgets
- **Development tools**:
  - `black` – code formatter
  - `isort` – import sorter
  - `pyupgrade` – modern Python syntax migration
  - `nbqa` – run QA tools on Jupyter notebooks
  - `ffmpeg` – multimedia processing
  - `threadpoolctl` – threadpool control
- **Font**: Intel One Mono (OTF)
- **Default shell**: `vscode` user with passwordless sudo

> For **technical details** — multi-stage build architecture, IPython configuration, environment variables, build arguments, layer caching, and extending the image — see the [technical README](docker/README.md).

#### Usage

Pull and run the image:

```bash
docker pull ghcr.io/cm032/images/python-clawpack:latest

docker run --rm -it \
  -p 8888:8888 \
  -v "$(pwd):/workspaces" \
  ghcr.io/cm032/images/python-clawpack:latest \
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

## CI/CD Pipeline

The Docker images are automatically built and published through **GitHub Actions**:

- **Trigger**: Push to `main` branch modifying `docker/python-clawpack.Dockerfile`, pull requests, or the 1st day of each month (scheduled)
- **Steps**:
  1. Maximize GitHub runner disk space
  2. Sparse clone the repository (only the `docker/` directory)
  3. Set up Docker Buildx with layer caching
  4. Build and push the image to GHCR
  5. Run a container vulnerability scan (critical severity threshold)
  6. Prune untagged images (keeping latest 2)

### Dependabot

[Dependabot](https://docs.github.com/code-security/dependabot) is configured to automatically update GitHub Actions dependencies on a **weekly** basis.

## Repository Structure

```
.
├── docker/
│   ├── python-clawpack.Dockerfile   # Dockerfile for the Clawpack image
│   └── README.md                    # Image-specific documentation
├── .github/
│   ├── dependabot.yml               # Dependabot configuration
│   └── workflows/
│       └── python-clawpack.yml      # CI/CD workflow
├── .dockerignore                    # Docker ignore rules
├── .gitignore                       # Git ignore rules
├── LICENSE                          # GNU GPL v2
└── README.md                        # This file
```

## Build Locally

To build the image on your local machine:

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

## License

This project is licensed under the **GNU General Public License v2.0**. See the [LICENSE](LICENSE) file for details.

## Author

- **Carlos Aznarán** – [caznaranl@uni.pe](mailto:caznaranl@uni.pe)

---

*Built with ❤️ for the scientific computing community.*
