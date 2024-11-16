#!/usr/bin/env bash

docker network create --driver bridge --subnet=172.20.80.0/24 doris-network 2>/dev/null || true


WORK_DIR="/data/var/lib/doris"
FE_PORT_1=8030
FE_PORT_2=9030
BE_PORT_1=8040

for i in {1..3}; do

NEXT_FE_PORT_1=$((FE_PORT_1 + (10000 * i)))
NEXT_FE_PORT_2=$((FE_PORT_2 + (10000 * i)))
name="fe-0$i"


mkdir -p "${WORK_DIR}"/"${name}"/fe/{doris-meta,log}

docker rm -f "${name}" 2>/dev/null || true
docker run \
-d \
--restart always \
--name "${name}" \
--hostname "${name}" \
--network doris-network \
--privileged=true \
--env TZ=Asia/Shanghai \
--env RUN_MODE=fe \
--env FE_SERVERS=fe1:fe-01:9010,fe2:fe-02:9010,fe3:fe-03:9010 \
--env FE_ID="$i" \
-v "${WORK_DIR}"/"${name}"/fe/doris-meta:/opt/apache-doris/fe/doris-meta \
-v "${WORK_DIR}"/"${name}"/fe/log:/opt/apache-doris/fe/log \
-p ${NEXT_FE_PORT_1}:8030 \
-p ${NEXT_FE_PORT_2}:9030 \
dyrnq/doris:2.1.7

done



for i in {1..3}; do
NEXT_BE_PORT_1=$((BE_PORT_1 + (10000 * i)))
name="be-0$i"
mkdir -p "${WORK_DIR}"/${name}/be/{storage,log}
docker rm -f "${name}" 2>/dev/null || true
docker run \
-d \
--restart always \
--name "${name}" \
--hostname "${name}" \
--network=doris-network \
--privileged=true \
--env TZ=Asia/Shanghai \
--env RUN_MODE=be \
--env FE_SERVERS=fe1:fe-01:9010,fe2:fe-02:9010,fe3:fe-03:9010 \
--env BE_ADDR="${name}:9050" \
-p ${NEXT_BE_PORT_1}:8040 \
-v "${WORK_DIR}"/${name}/be/storage:/opt/apache-doris/be/storage \
-v "${WORK_DIR}"/${name}/be/log:/opt/apache-doris/be/log \
dyrnq/doris:2.1.7
done


docker exec -it fe-01 bash -c "mysql -uroot -P9030 -hfe-01 -e 'show frontends;show backends;' "