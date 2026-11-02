FROM ubuntu:24.04

ARG USER
ARG GROUP=${USER}
ARG UID
ARG GID

ENV USER=${USER} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Tokyo

# hadolint ignore=DL3008
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    curl \
    sudo \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remove the default 'ubuntu' user (UID/GID 1000) to avoid conflicts
RUN if id -u ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi && \
    groupadd --gid ${GID} ${GROUP} && \
    useradd --uid ${UID} --gid ${GID} --shell /bin/bash --create-home ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
