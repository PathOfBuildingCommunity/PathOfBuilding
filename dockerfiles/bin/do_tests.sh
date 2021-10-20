#!/bin/sh
docker-compose up -d
while [ $(docker ps -q -f name=busted) ]
do
  sleep 1s
done
LOGS_LENGTH=$(docker logs -f busted | wc -l)
LAST_START=$(docker logs -f busted | grep -n "Loading main script..." | tail -1 | cut -d : -f 1)
docker logs --tail $((LOGS_LENGTH - LAST_START + 1)) -f busted > spec/test_results.log