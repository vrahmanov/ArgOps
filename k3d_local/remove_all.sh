#!/bin/sh
docker system prune -f
docker rmi $(docker images -aq) -f
docker network prune -f
docker volume prune -f