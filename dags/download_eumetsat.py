# -*- coding: utf-8 -*-
from __future__ import print_function

import time
from builtins import range
from pprint import pprint

from airflow.utils.dates import days_ago
from airflow.models import DAG
from airflow.operators.python_operator import PythonOperator
from satip.eumetsat import DownloadManager
import dotenv
import os

env_vars_fp = "/srv/airflow/.env"
data_dir = "/srv/airflow/data/raw"
sorted_dir = "/srv/airflow/data/sorted"
metadata_db_fp = "/srv/airflow/data/EUMETSAT_metadata.db"
debug_fp = "/srv/airflow/debug/EUMETSAT_download.txt"
BUCKET_NAME = "solar-pv-nowcasting-data"
PREFIX = "satellite/EUMETSAT/SEVIRI_RSS/native/2020"


args = {
    "owner": "Airflow",
    "start_date": days_ago(2),
}

dag = DAG(
    dag_id="download_all_EUMETSAT",
    default_args=args,
    schedule_interval=None,
    tags=["download"],
)


def download_eumetsat(start_date="2020-01-01 00:00", end_date="2020-01-02 00:00"):
    """Creates DownloadManager object, then downloads files for 2020"""
    start_date = "2020-01-01 00:00"
    end_date = "2020-02-01 00:00"
    dotenv.load_dotenv(env_vars_fp)
    user_key = os.environ.get("USER_KEY")
    user_secret = os.environ.get("USER_SECRET")
    dm = DownloadManager(
        user_key,
        user_secret,
        data_dir,
        metadata_db_fp,
        debug_fp,
        bucket_name=BUCKET_NAME,
        bucket_prefix=PREFIX,
    )
    dm.download_datasets(start_date, end_date)


task = PythonOperator(
    task_id="download_EUMETSAT",
    provide_context=False,
    python_callable=download_eumetsat,
    dag=dag,
)

with dag as d:
    task
