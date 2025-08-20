#!/bin/sh
set -e

echo ">>> Starting Minecraft entrypoint..."

java -Xmx${JVM_XMX} -Xms${JVM_XMS} -jar ./velocity-3.4.0.jar nogui
