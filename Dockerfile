FROM python:3.12-slim-bookworm AS crtm-era5-build

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    git \
    git-lfs \
    wget \
    curl \
    cmake \
    ninja-build \
    libnetcdf-dev \
    libnetcdff-dev \
    openmpi-bin \
    ecbuild \
    ssh \
    ca-certificates \
    patch \
    pipx \
    g++ \
    pipx \
    pbzip2 \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /root

# Add github to known hosts
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone and patch CRTM
COPY 0001-Fix-download-link-for-binary-files.patch /root/0001-Fix-download-link-for-binary-files.patch
RUN git clone -b master --depth 1 https://github.com/JCSDA/crtm.git && \
    cd crtm && \
    git apply ../0001-Fix-download-link-for-binary-files.patch

# Unpack data files
ARG COEF_TAR
ADD ${COEF_TAR} /root/crtm/
WORKDIR /root/crtm
RUN mv fix_crtm-internal_develop fix

# Build / install CRTM
ARG JOBS
RUN mkdir /root/crtm/build
WORKDIR /root/crtm/build
RUN ecbuild --static --log=DEBUG ..
RUN make -j$(JOBS)
RUN make install

# Copy all of the coefficients EXCEPT the TauCoeff, because they are massive and instrument specific
RUN mkdir /root/crtm-coefficients && \ 
    cp /root/crtm/fix/AerosolCoeff/Little_Endian/* /root/crtm-coefficients/  && \
    cp /root/crtm/fix/CloudCoeff/Little_Endian/* /root/crtm-coefficients/  && \
    cp /root/crtm/fix/EmisCoeff/**/Little_Endian/* /root/crtm-coefficients/  && \
    cp /root/crtm/fix/SpcCoeff/Little_Endian/* /root/crtm-coefficients/ && \
    cp /root/crtm/fix/TauCoeff/ODAS/Little_Endian/atms_npp.TauCoeff.bin /root/crtm-coefficients/atms_npp.TauCoeff.bin

COPY herbie_config.toml /root/.config/herbie/config.toml

# Configure pipx to install to path already in PATH
ENV PIPX_BIN_DIR=/usr/local/bin
# we should install the versiioning plugin here `&& pipx inject poetry "poetry-dynamic-versioning[plugin]"`
# but if we do then pseudodata-dev build needs the .git folder copied in for the versioning to work. I'm not sure why it works 
# without (when it just installs the plugin locally to the project in the next step)
RUN pipx install 'poetry>=2' 

ENV POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    CC=gcc

WORKDIR /root/work

