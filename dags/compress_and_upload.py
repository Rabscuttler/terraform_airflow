# -*- coding: utf-8 -*-
from __future__ import print_function

import time
from builtins import range
from pprint import pprint

from airflow.utils.dates import days_ago
from airflow.models import DAG
from airflow.operators.python_operator import PythonOperator
from satip.eumetsat import compress_downloaded_files, upload_compressed_files
import os

env_vars_fp = "/srv/airflow/.env"
data_dir = "/srv/airflow/data/raw"
sorted_dir = "/srv/airflow/data/sorted"
metadata_db_fp = "/srv/airflow/data/EUMETSAT_metadata.db"
debug_fp = "/srv/airflow/debug"
BUCKET_NAME = "solar-pv-nowcasting-data"
PREFIX = "satellite/EUMETSAT/SEVIRI_RSS/native/"

import logging as log


args = {
    "owner": "Airflow",
    "start_date": days_ago(2),
}

dag = DAG(
    dag_id="compress_upload",
    default_args=args,
    schedule_interval=None,
    tags=["download"],
)


def compress_files():
    """Compresses downloaded .nat files"""
    compress_downloaded_files(data_dir=data_dir, sorted_dir=sorted_dir, log=log)


def upload_files():
    """Upload compressed files to GCP storage"""
    upload_compressed_files(sorted_dir, BUCKET_NAME, PREFIX, log=log)


task1 = PythonOperator(
    task_id="compress_files",
    provide_context=False,
    python_callable=compress_files,
    dag=dag,
)

task2 = PythonOperator(
    task_id="upload_files",
    provide_context=False,
    python_callable=upload_files,
    dag=dag,
)

with dag as d:
    task1 >> task2

