
# docker buildx build  -t pycrtm-base:test --ssh default --platform linux/amd64 --progress=plain -f Dockerfile  .

ARG PYTHON_VERSION=3.12
ARG USERNAME=wxs
ARG USER_UID=1000
ARG USER_GID=988 #group id for docker group on altair

FROM python:${PYTHON_VERSION}-slim-bookworm AS base

ARG USERNAME
ARG USER_UID
ARG USER_GID    
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

FROM base AS crtm-builder

ARG USERNAME

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    git \
    git-lfs \
    wget \
    ninja-build \
    cmake \
    libnetcdf-dev \
    libnetcdff-dev \
    openmpi-bin \
    ecbuild \
    ssh \
    ca-certificates \
    patch \
    pipx \
    && rm -rf /var/lib/apt/lists/*

# not sure why crtm is owned by root in the final image, but this avoids permission issues later
RUN mkdir /home/$USERNAME/crtm && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/crtm

USER $USERNAME

# Set up working directory
WORKDIR /home/$USERNAME 

# Add github to known hosts
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN git clone -b release/REL-2.4.0 --depth 1 https://github.com/OrbitalMicro/crtm2.4.git /home/$USERNAME/crtm

# # Unpack data files
# Download and extract additional coefficient files for CRTM
ARG CRTM_VERSION=2.4.0
ARG CRTM_FIX_REL_CACHEBUSTER=0
RUN wget --quiet -nc -O /tmp/fix_REL.tgz ftp://ftp.ssec.wisc.edu/pub/s4/CRTM/fix_REL-${CRTM_VERSION}.tgz
RUN mkdir /home/$USERNAME/crtm/fix && tar -xvzf /tmp/fix_REL.tgz --directory /home/$USERNAME/crtm/fix --strip-components=1 && \
    rm /tmp/fix_REL.tgz

WORKDIR /home/$USERNAME/crtm

# # Build / install CRTM
ARG JOBS=10
RUN mkdir /home/$USERNAME/crtm/build
WORKDIR /home/$USERNAME/crtm/build
RUN ecbuild --static --log=DEBUG ..
RUN make -j${JOBS}
RUN sudo make install

WORKDIR /home/$USERNAME
USER $USERNAME

# Copy other crtm coefficients
RUN mkdir /home/$USERNAME/crtm-coefficients && \
    cp crtm/fix/AerosolCoeff/Little_Endian/* /home/$USERNAME/crtm-coefficients/  && \
    cp crtm/fix/CloudCoeff/Little_Endian/* /home/$USERNAME/crtm-coefficients/  && \
    cp crtm/fix/EmisCoeff/**/Little_Endian/* /home/$USERNAME/crtm-coefficients/  && \
    cp crtm/fix/SpcCoeff/Little_Endian/* /home/$USERNAME/crtm-coefficients/ && \
    cp crtm/fix/TauCoeff/ODAS/Little_Endian/atms_npp.TauCoeff.bin /home/$USERNAME/crtm-coefficients/


# Configure pipx to install to known location
ENV PIPX_BIN_DIR=/home/$USERNAME/.local/bin
ENV PATH="$PIPX_BIN_DIR:$PATH"
# we should install the versiioning plugin here `&& pipx inject poetry "poetry-dynamic-versioning[plugin]"`
# but if we do then we need the .git folder copied into the image for the versioning to work when we run `poetry sync`. letting it 
# create a local copy seems to skip the git check. I'm not sure why it works 
# without (when it just installs the plugin locally to the project in the next step)
RUN pipx install 'poetry>=2' 

ENV POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    CC=gcc

FROM base AS pygems-base

ARG USERNAME
ARG USER_UID
ARG USER_GID

# Install system dependencies. build-essential for pygems
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    libnetcdf19 \
    libnetcdff7 \
    openmpi-bin \
    build-essential \
    pipx \
    pbzip2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=crtm-builder /usr/local /usr/local
COPY --chown=${USER_UID}:${USER_GID} --from=crtm-builder /home/$USERNAME/crtm-coefficients /home/$USERNAME/crtm-coefficients

WORKDIR /home/$USERNAME
USER $USERNAME

# Configure pipx to install to known location
ENV PIPX_BIN_DIR=/home/$USERNAME/.local/bin
ENV PATH="$PIPX_BIN_DIR:$PATH"
ENV POETRY_DYNAMIC_VERSIONING_COMMANDS="build,publish"
RUN pipx install 'poetry>=2 ' && \
    pipx inject poetry "poetry-dynamic-versioning[plugin]"

ENV POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    CC=gcc

