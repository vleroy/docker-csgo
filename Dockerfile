FROM ubuntu:focal

ENV TERM xterm

ENV STEAM_DIR /home/steam
ENV STEAMCMD_DIR /home/steam/steamcmd
ENV CSGO_APP_ID 740
ENV CSGO_DIR /home/steam/csgo

SHELL ["/bin/bash", "-c"]

ARG STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

RUN set -xo pipefail
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
    lib32gcc1 \
    lib32stdc++6 \
    lib32z1 \
    ca-certificates \
    net-tools \
    locales \
    curl \
    unzip
RUN locale-gen en_US.UTF-8 
RUN adduser --disabled-password --gecos "" steam 
RUN mkdir ${STEAMCMD_DIR} 
RUN cd ${STEAMCMD_DIR} 
RUN curl -sSL ${STEAMCMD_URL} | tar -zx -C ${STEAMCMD_DIR} 
RUN mkdir -p ${STEAM_DIR}/.steam/sdk32 
RUN ln -s ${STEAMCMD_DIR}/linux32/steamclient.so ${STEAM_DIR}/.steam/sdk32/steamclient.so 
RUN { \ 
    echo '@ShutdownOnFailedCommand 1'; \
    echo '@NoPromptForPassword 1'; \
    echo 'login anonymous'; \
    echo 'force_install_dir ${CSGO_DIR}'; \
    echo 'app_update ${CSGO_APP_ID}'; \
    echo 'quit'; \
} > ${STEAM_DIR}/autoupdate_script.txt
RUN mkdir ${CSGO_DIR}
RUN chown -R steam:steam ${STEAM_DIR} 
RUN rm -rf /var/lib/apt/lists/

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

COPY --chown=steam:steam containerfs ${STEAM_DIR}/

USER steam

# Force download to include CSGO files in image
RUN ${STEAMCMD_DIR}/steamcmd.sh +login anonymous +force_install_dir ${CSGO_DIR} +app_update ${CSGO_APP_ID} validate +quit

WORKDIR ${CSGO_DIR}
VOLUME ${CSGO_DIR}
ENTRYPOINT exec ${STEAM_DIR}/start.sh
