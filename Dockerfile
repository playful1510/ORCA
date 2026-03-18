# 1) choose base container
# generally use the most recent tag

# base notebook, contains Jupyter and relevant tools
# See https://github.com/ucsd-ets/datahub-docker-stack/wiki/Stable-Tag 
# for a list of the most current containers we maintain
ARG BASE_CONTAINER=ghcr.io/ucsd-ets/datahub-base-notebook:stable

FROM $BASE_CONTAINER

LABEL maintainer="UC San Diego ITS/ETS <ets-consult@ucsd.edu>"

# 2) change to root to install packages
USER root

RUN apt-get update -q && \
    apt-get install -q -y --no-install-recommends \
    apt-get -y install htop \
        git \
        zsh \
        sudo \
        curl \
        bzip2 \
        openmpi-bin = 4.1.8 \
        openmpi-doc \
        openmpi-common \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# 3) install packages using notebook user
USER jovyan

# RUN conda install -y scikit-learn

RUN pip install --no-cache-dir networkx scipy

# Override command to disable running jupyter notebook at launch
# CMD ["/bin/bash"]
# Micromamba Installation
## The original Micromamba way
## https://mamba.readthedocs.io/en/latest/micromamba-installation.html
## with
## RUN curl -Ls \
##     https://micro.mamba.pm/api/micromamba/linux-64/latest \
##     | tar -xvj /bin/micromamba
## did not work, so the binary provided directly:
COPY micromamba /bin/micromamba

# Set user and group
ARG USER=orcauser
ARG GROUP=orca
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${GROUP}
RUN useradd -l -u ${UID} -g ${GROUP} -s /bin/zsh -m ${USER}
RUN passwd -d ${USER}
RUN usermod -a -G sudo ${USER}
USER ${UID}:${GID}
WORKDIR /home/${USER}

# Install Python Environment
ADD --chown=${USER}:${GROUP} .zshrc ./
ADD --chown=${USER}:${GROUP} environment-slim.yml ./
RUN micromamba shell init --shell zsh --root-prefix=~/micromamba
RUN micromamba create -f environment-slim.yml

# Install Orca
ADD --chown=${USER}:${GROUP} orca.tar.xz ./

CMD ["zsh"]
