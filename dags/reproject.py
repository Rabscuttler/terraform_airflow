# -*- coding: utf-8 -*-
from __future__ import print_function

import time
from builtins import range
from pprint import pprint

from airflow.utils.dates import days_ago
from airflow.models import DAG
from airflow.operators.python_operator import PythonOperator
from satip.reproj import Reprojector
import os

new_coords_fp = f"{intermediate_data_dir}/reproj_coords_TM_4km.csv"
new_grid_fp = "../data/intermediate/new_grid_4km_TM.json"
reprojector = Reprojector(new_coords_fp, new_grid_fp)

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
    dag_id="reproject", default_args=args, schedule_interval=None, tags=["download"],
)


def reproject():
    """Reprojects downloaded .nat files"""
    ds_reproj = reprojector.reproject(native_fp, reproj_library="pyinterp")

    reprojected_dss = [
        (
            reprojector.reproject(filepath, reproj_library="pyinterp").pipe(
                io.add_constant_coord_to_da, "time", pd.to_datetime(datetime)
            )
        )
        for datetime, filepath in datetime_to_filepath.items()
    ]

    if len(reprojected_dss) > 0:
        ds_combined_reproj = xr.concat(
            reprojected_dss, "time", coords="all", data_vars="all"
        )
        return ds_combined_reproj
    else:
        return xr.Dataset()


task1 = PythonOperator(
    task_id="reproject", provide_context=False, python_callable=reproject, dag=dag,
)

with dag as d:
    task1

