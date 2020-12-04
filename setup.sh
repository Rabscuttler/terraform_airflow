#!/bin/bash
set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

docker pull puckel/docker-airflow

docker run -d -p 8080:8080 puckel/docker-airflow webserver


docker run -d \
  --mount type=bind,source="$(pwd)"/dags,target=/usr/local/airflow/dags \
  --mount type=bind,source="$(pwd)"/downloads,target=/usr/local/airflow/downloads \
  -p 8080:8080 puckel/docker-airflow webserver