# Installing Airflow on a GCP VM

# This tutorial was quite helpful but there were a few bugs I had to work through.
# https://medium.com/grensesnittet/airflow-on-gcp-may-2020-cdcdfe594019
# Bugs:
# Watch out for quotation marks from Medium
# systemctl scheduler service files needed slightly adjusting.
# The postgresql localhost part of the argument was dropped


sudo su
apt update
apt upgrade
apt-get install build-essential


############################################
# Installing Airflow
############################################
apt-get install -y --no-install-recommends \
        freetds-bin \
        krb5-user \
        ldap-utils \
        libffi6 \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc

apt install software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt install python3.7 python3.7-venv python3.7-dev

# add airflow system user
adduser airflow --disabled-login --disabled-password --gecos "Airflow system user"

################## OPTIONAL ##################
# install conda
sudo su airflow # as airflow user
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p ~/miniconda 
rm ~/miniconda.sh
export PATH=~/miniconda/bin:$PATH
# add environment.yml file
conda env create -f environment.yml
conda init bash
conda activate satip_dev
#############################################

# Setup folder and virtualenv
cd /srv
# don't need this virtualenv if using conda
python3.7 -m venv airflow
cd airflow
source bin/activate

# With an activated virtual environment
pip install --upgrade pip
pip install wheel
pip install apache-airflow[postgres,google,crypto]==1.10.10
chown airflow.airflow . -R
chmod g+rwx . -R


############################################
# Installing the database
############################################
apt install postgresql postgresql-contrib
sudo -i -u postgres
createuser --interactive
# username: airflow
# superuser: y
createdb airflow

# change airflow configuration
# vim /srv/airflow/airflow.cfg
# Change SequentialExecutor to LocalExecutor
executor = LocalExecutor
# And the sql_alchemy_conn 
sql_alchemy_conn = postgresql+psycopg2:///airflow

# Change database owner to airflow so it has control over it through sqlalchemy
sudo -u postgres psql -c "ALTER DATABASE airflow OWNER TO airflow"
# Set password for user airflow to airflow
sudo -u postgres psql -c "ALTER USER airflow PASSWORD 'airflow'"

############################################
# Running airflow
############################################

# As airflow user
sudo su airflow
cd /srv/airflow
conda activate satip_dev
#source bin/activate
export AIRFLOW_HOME=/srv/airflow
airflow initdb

# Create a new admin user
airflow create_user -r Admin -u laurence -e laurence@futureenergy.associates -f Laurence -l Watson

# Start the webserver
airflow webserver -p 8080
# Start the scheduler
airflow scheduler


############################################
# Automatic startup
############################################

# Create file `airflow-webserver.service` with the below content

[Unit]
Description=Airflow webserver daemon
After=network.target postgresql.service

[Service]
Environment="PATH=/srv/airflow/bin"
Environment="AIRFLOW_HOME=/srv/airflow"
User=airflow
Group=airflow
Type=simple
ExecStart=/srv/airflow/bin/airflow webserver -p 8080 --pid /srv/airflow/airflow-webserver.pid
Restart=always
RestartSec=5s
PrivateTmp=true

[Install]
WantedBy=multi-user.target

# Then:
sudo cp airflow-webserver.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable airflow-webserver.service
sudo systemctl start airflow-webserver.service
sudo systemctl status airflow-webserver.service

# Same for `airflow-scheduler.service`

[Unit]
Description=Airflow scheduler daemon
After=network.target postgresql.service
[Service]
Environment="PATH=/srv/airflow/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
Environment="AIRFLOW_HOME=/srv/airflow"
User=airflow
Group=airflow
Type=simple
ExecStart=/srv/airflow/bin/airflow scheduler
Restart=always
RestartSec=5s
[Install]
WantedBy=multi-user.target

# Now run
sudo cp airflow-scheduler.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable airflow-scheduler.service
sudo systemctl start airflow-scheduler.service
sudo systemctl status airflow-scheduler.service


# Setup Web Authentication
# in airflow.cfg set
[webserver]
authenticate = True
auth_backend = airflow.contrib.auth.backends.password_auth
# Comment out auth_backend for the API

# As airflow user, enable virtualenv
# and in virtualenv
pip install password bcrypt flask-bcrypt

# Then create user

# Don't forget to add sqlalchemy db engine as per this answer
# https://stackoverflow.com/questions/51822227/airflow-basic-auth-cannot-login-with-created-user

# if airflow user isn't the owner of the postgresql database, this will fail
python
# In python console
from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser
user = PasswordUser(models.User())
user.username = 'admin'
user.email = 'user@email.com'
user.password = 'openclimatefix'

from sqlalchemy import create_engine
# note airflow:airflow is username:password for postgres we set up earlier
engine = create_engine("postgresql://airflow:airflow@localhost:5432/airflow")

session = settings.Session(bind=engine)
session.add(user)
session.commit()
session.close()
exit()


#############
# Specific needs for SATIP downloads

# Install reqs for satip
# Create dirs for satip
# sudo apt-get install -y pbzip2
