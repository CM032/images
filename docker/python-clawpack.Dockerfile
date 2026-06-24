# Copyleft (c) June, 2026, Carlos Aznarán

FROM ghcr.io/cpp-review-dune/introductory-review/aur AS build

ARG AUR_PACKAGES="\
  python-clawpack \
  "

ARG EXTRA_AUR_PACKAGES="\
  jupyter-nbgrader \
  nbqa \
  otf-intel-one-mono \
  python-jupyterlab-variableinspector \
  "

RUN yay --repo --needed --noconfirm --noprogressbar -Syuq >/dev/null 2>&1 && \
  yay --mflags --nocheck --needed --noconfirm --noprogressbar -S ${AUR_PACKAGES} >/dev/null 2>&1 && \
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
  bat \
  asciinema \
  blas-openblas \
  ffmpeg \
  gemini-cli \
  git \
  jupyterlab-rise \
  jupyterlab-widgets \
  less \
  python-black \
  python-isort \
  python-ipympl \
  python-jupyter-server-terminals \
  python-numpy \
  python-pandas \
  python-pytest \
  python-scipy \
  python-threadpoolctl \
  pyupgrade \
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
  echo -e "c.IPythonWidget.font_size = 11\nc.IPythonWidget.font_family = 'Intel One Mono'\nc.IPKernelApp.matplotlib = 'inline'\nc.InlineBackend.figure_format = 'retina'\n" >> ~/.ipython/profile_default/ipython_config.py

ENV PYDEVD_DISABLE_FILE_VALIDATION=1

EXPOSE 8888

WORKDIR /workspaces