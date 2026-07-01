# Copyleft (c) June, 2026, Carlos Aznarán

FROM ghcr.io/cpp-review-dune/introductory-review/aur AS build

ARG EXTRA_AUR_PACKAGES="\
  jupyter-nbgrader \
  nbqa \
  otf-intel-one-mono \
  python-jupyterlab-variableinspector \
  "

RUN yay --repo --needed --noconfirm --noprogressbar -Syuq >/dev/null 2>&1 && \
  yay --repo --needed --noconfirm --noprogressbar -S ${OPT_PACKAGES} >/dev/null 2>&1 && \
  yay --mflags --nocheck --needed --noconfirm --noprogressbar -S ${EXTRA_AUR_PACKAGES} 2>&1 | tee -a /tmp/$(date -u +"%Y-%m-%d-%H-%M-%S" --date='5 hours ago').log >/dev/null

LABEL maintainer="Carlos Aznarán <caznaranl@uni.pe>" \
  name="CM032" \
  description="Clawpack packages for CM032" \
  url="https://github.com/orgs/cm032/packages/container/package/images%2Fclawpack" \
  vcs-url="https://github.com/cm032/images" \
  vendor="Oromion Aznarán" \
  version="1.0"

FROM archlinux:base-devel

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN ln -s /usr/share/zoneinfo/America/Lima /etc/localtime && \
  sed -i 's/^#Color/Color/' /etc/pacman.conf && \
  sed -i 's/^#DisableSandbox/DisableSandbox/' /etc/pacman.conf && \
  sed -i 's/^#DownloadUser/DownloadUser/' /etc/pacman.conf && \
  sed -i '/#CheckSpace/a ILoveCandy' /etc/pacman.conf && \
  sed -i 's/^ParallelDownloads = 5/ParallelDownloads = 30/' /etc/pacman.conf && \
  sed -i 's/^VerbosePkgLists/#VerbosePkgLists/' /etc/pacman.conf && \
  sed -i 's/ usr\/share\/doc\/\*//g' /etc/pacman.conf && \
  sed -i 's/usr\/share\/man\/\* //g' /etc/pacman.conf && \
  sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf && \
  sed -i 's/^#BUILDDIR/BUILDDIR/' /etc/makepkg.conf && \
  echo -e '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist' | tee -a /etc/pacman.conf && \
  groupadd -g $USER_GID $USERNAME && \
  useradd -l -u $USER_UID -md /home/$USERNAME -s /bin/bash -g $USER_GID $USERNAME && \
  passwd -d $USERNAME && \
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USERNAME && \
  chmod 0440 /etc/sudoers.d/90-$USERNAME && \
  sed -i "s/PS1='\[\\\u\@\\\h \\\W\]\\\\\\$ '//g" /home/$USERNAME/.bashrc && \
  { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> /home/$USERNAME/.bashrc

USER $USERNAME

ARG PACKAGES="\
  asciinema \
  bat \
  ffmpeg \
  gemini-cli \
  git \
  jupyterlab-rise \
  jupyterlab-widgets \
  python-black \
  python-isort \
  python-ipympl \
  python-jupyter-server-terminals \
  python-pandas \
  python-threadpoolctl \
  blas-openblas \
  python-numpy-mkl \
  python-scipy-mkl \
  gmsh \
  python-pyvista \
  python-trame \
  python-trame-vtk \
  python-trame-vuetify \
  jupyter-collaboration \
  xorg-fonts-100dpi \
  xorg-server-xvfb \
  less \
  pyupgrade \
  yay \
  tldr \
  python-fenics-dolfinx \
  gmsh \
  python-imageio \
  "

ARG VTK_PACKAGES="\
  adios2 \
  cgns \
  ffmpeg \
  fmt \
  gl2ps \
  glew \
  hdf5-openmpi \
  jsoncpp \
  libxcursor \
  openvr \
  openxr \
  ospray \
  netcdf-openmpi \
  mariadb-libs \
  liblas \
  libharu \
  pdal \
  postgresql-libs \
  qt5-base \
  verdict \
  "

COPY --from=build /tmp/*.log /tmp/
COPY --from=build /home/builder/.cache/yay/*/*.pkg.tar.zst /tmp/

RUN curl -s https://gitlab.com/dune-archiso/dune-archiso.gitlab.io/-/raw/main/templates/add_arch4edu.sh | bash && \
  sudo pacman-key --init && \
  sudo pacman-key --populate archlinux && \
  sudo pacman --needed --noconfirm --noprogressbar -Sy archlinux-keyring && \
  sudo pacman --needed --noconfirm --noprogressbar -Syuq >/dev/null 2>&1 && \
  sudo pacman --needed --noconfirm --noprogressbar -S ${PACKAGES} && \
  sudo pacman --noconfirm -U /tmp/*.pkg.tar.zst && \
  sudo rm -r /tmp/*.pkg.tar.zst && \
  find /tmp/ ! -name '*.log' -type f -exec rm -f {} + && \
  sudo pacman -Scc <<< Y <<< Y && \
  sudo rm -r /var/lib/pacman/sync/* && \
  ipython profile create && \
  echo -e "c.IPythonWidget.font_size = 11\nc.IPythonWidget.font_family = 'Intel One Mono'\nc.IPKernelApp.matplotlib = 'inline'\nc.InlineBackend.figure_format = 'retina'\n" >> ~/.ipython/profile_default/ipython_config.py && \
  echo "alias startJupyter=\"jupyter-lab --port=8888 --no-browser --ip=0.0.0.0 --NotebookApp.allow_origin='*' --NotebookApp.token='' --NotebookApp.password=''\"" >> ~/.bashrc

ENV PYTHONPATH=/usr/share/gmsh/api/python
ENV TRAME_DISABLE_V3_WARNING="1"
ENV DISPLAY=":99.0"
ENV PYVISTA_OFF_SCREEN="true"
ENV PYVISTA_TRAME_SERVER_PROXY_PREFIX="/proxy/"
ENV PYVISTA_TRAME_SERVER_PROXY_ENABLED="True"
ENV PYVISTA_JUPYTER_BACKEND="trame"
ENV MKL_THREADING_LAYER=gnu
ENV PETSC_DIR=/opt/petsc/linux-c-opt
ENV PYTHONPATH=$PETSC_DIR/lib
ENV PYDEVD_DISABLE_FILE_VALIDATION=1

EXPOSE 8888

WORKDIR /workspaces