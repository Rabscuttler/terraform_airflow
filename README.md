# Reusable Airflow Configuration with Terraform and Docker

## Motivation

We want to deploy [Airflow] in a repeatable and scaleable (to zero) way.  
This suggests Infrastructure As Code, for example using `terraform` for repeatable deployments.  

By creating and storing infrastructure provisioning, we create a historical record in git, repeatable recipes for infrastructure for future users, and hopefully a more robust deployment framework.  

OCF is using Google Cloud Platform. But projects may need to work with other clouds. Users of OCF's software tools may use other cloud providers. So ideally, infrastructure provisioning and tooling should be as flexible as possible.  

## Requirements

### Terraform

Install `Terraform` with instructions here: <https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started>  

### Docker

Install `Docker Desktop` with instructions here: <https://docs.docker.com/desktop/>  


## Windows configuration

Windows needs a different docker provider in `main.tf`:  

```tf
provider "docker" {
  host    = "npipe:////.//pipe//docker_engine"
}
```

## Setup

As per the `Terraform` instructions, create a service account in project root.  
Add it to `.gitignore` - we don't want this service account key getting in to version control under any circumstances.  

## Cloud images

List all available cloud images on GCP with `gcloud compute images list`.  

## Using Terraform

After installation, install required plugins with `terraform init`  

After making any changes to the `main.tf` file, apply changes and deploy infrastructure with `terraform apply`. Type `yes` upon prompt to accept the planned changes.  

Terraform doesn't mind what order resources are declared in `main.tf`, it will ensure dependencies are followed when resources are created.

We can save our plans to a file e.g.  
`terraform plan -out static_ip`  

This ensures we can apply exactly the same plan in the future.  

## Airflow with Docker

<https://github.com/puckel/docker-airflow>


`docker-compose -f docker-compose-LocalExecutor.yml up -d`

`docker pull puckel/docker-airflow`
`docker run -d -p 8080:8080 puckel/docker-airflow webserver`


## Setting up Airflow on GCP VM

Open up network traffic:  

`gcloud compute firewall-rules create allow-8080-traffic --allow tcp:8080 --source-tags=airflow --source-ranges=0.0.0.0/0 --description="Allow TCP 8080 connections for airflow webserver"`  

Start airflow VM:  
`gcloud compute instances start airflow`  

Stop airflow VM:
`gcloud compute instances stop airflow`


## Testing Airflow locally
Run local dockerised Airflow in SequentialExecutor mode, mounting the relative `dags` folder the the correct place in the container.  
`docker run -d --mount type=bind,source="$(pwd)"/dags,target=/usr/local/airflow/dags \
   -p 8080:8080 puckel/docker-airflow webserver`



## GCP Utils
Check folder size on a bucket
`gsutil du -h -s gs://solar-pv-nowcasting-data/satellite/EUMETSAT/SEVIRI_RSS/native/2018/01/01`  
Answer: 3.1TB per year, 8.58GB in one day

