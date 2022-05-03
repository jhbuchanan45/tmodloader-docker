FROM alpine:3.11 as build

ARG TMOD_VERSION=0.11.7.8
ARG TERRARIA_VERSION=1412

RUN apk update &&\
    apk add --no-cache --virtual build curl unzip

RUN mkdir /terraria-server

ADD "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip" /

RUN unzip terraria-server-*.zip -d /terraria && \
    mv /terraria/$TERRARIA_VERSION/Linux/* /terraria-server && \
    #Linux subfolder does not include any config text file, oddly.
    mv /terraria/$TERRARIA_VERSION/Windows/serverconfig.txt /terraria-server/serverconfig-default.txt && \
    chmod +x /terraria-server/TerrariaServer && \
    chmod +x /terraria-server/TerrariaServer.bin.x86_64


ADD "https://github.com/tModLoader/tModLoader/releases/download/v${TMOD_VERSION}/tModLoader.Linux.v${TMOD_VERSION}.tar.gz" /

RUN tar -xvzf tModLoader.Linux.v*.tar.gz --overwrite --directory /terraria-server

WORKDIR /terraria-server

RUN cp tModLoader-mono tModLoaderServer && \
    chmod u+x tModLoaderServer*

FROM mono:6.12
LABEL org.opencontainers.image.authors="Jacob Buchanan <jhabuchanan522@gmail.com>"

EXPOSE 7777
ENV TMOD_SHUTDOWN_MSG="Shutting down!"
ENV TMOD_AUTOSAVE_INTERVAL="*/10 * * * *"
ENV TMOD_IDLE_CHECK_INTERVAL=""
ENV TMOD_IDLE_CHECK_OFFSET=0

RUN apt-get update &&\
    apt-get install -y tmux cron pcregrep &&\
    apt-get clean

WORKDIR /terraria-server
COPY --from=build /terraria-server ./

RUN ln -s ${HOME}/.local/share/Terraria/ /terraria
COPY inject.sh /usr/local/bin/inject
COPY handle-idle.sh /usr/local/bin/handle-idle

COPY config.txt entrypoint.sh ./
RUN chmod +x entrypoint.sh /usr/local/bin/inject /usr/local/bin/handle-idle

VOLUME ["/terraria", "/terraria-server/config.txt"]

ENTRYPOINT [ "/terraria-server/entrypoint.sh" ]
