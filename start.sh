#!/bin/sh
set -e

echo ">>> Starting Minecraft entrypoint..."

java -Xmx${JVM_XMX} -Xms${JVM_XMS} -jar ./server.jar nogui
