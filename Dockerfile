FROM eclipse-temurin:21-jdk-alpine

WORKDIR /minecraft

COPY ./ .

EXPOSE 25565

ENV JVM_XMX=2G
ENV JVM_XMS=1G

# Make shell verbose
SHELL ["/bin/sh", "-c"]
RUN apk add --no-cache curl unzip jq

RUN echo ">>> Installing curl and unzip..." \
 && apk add --no-cache curl unzip \
 && echo ">>> Packages installed."

RUN echo ">>> Making start.sh executable..." \
 && chmod +x ./start.sh

# Set entrypoint
ENTRYPOINT ["./start.sh"]

