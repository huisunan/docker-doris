#!/usr/bin/env bash

docker network create --driver bridge --subnet=172.20.80.0/24 doris-network 2>/dev/null || true

name=std

WORK_DIR="/data/var/lib/doris"
mkdir -p "${WORK_DIR}"/std/be/{storage,log}
mkdir -p "${WORK_DIR}"/std/fe/{doris-meta,log}

docker rm -f "${name}" 2>/dev/null || true
docker run \
-d \
--restart always \
--name "${name}" \
--hostname "standalone" \
--network doris-network \
--env TZ=Asia/Shanghai \
--env RUN_MODE=standalone \
--privileged=true \
-p 8030:8030 \
-p 9030:9030 \
-v "${WORK_DIR}"/std/fe/doris-meta:/opt/apache-doris/fe/doris-meta \
-v "${WORK_DIR}"/std/fe/log:/opt/apache-doris/fe/log \
-v "${WORK_DIR}"/std/be/storage:/opt/apache-doris/be/storage \
-v "${WORK_DIR}"/std/be/log:/opt/apache-doris/be/log \
dyrnq/doris:2.1.7

while true; do
    sleep 3s && docker exec -it std bash -c "mysql -uroot -P9030 -h127.0.0.1 -e 'show frontends;show backends;' " && break;
done