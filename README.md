# Deploy CF Deployment on AWS

## Prerequisites

### AWS limits

| Instance type | Required instances |
|---------------|--------------------|
| m4.large      | 30                 |
| m4.xlarge     | 1                  |
| r4.xlarge     | 2                  |
| c4.large      | 6                  |
| t2.medium     | 1                  |
| t2.micro      | 1                  |

### System requirements

* bbl (tested on v6.7.8)
* bosh-cli >= v2.0.48
* terraform >= 0.11.0
* ruby (necessary for bosh create-env) tested with v2.4.0
* `git clone --recursive https://github.com/crsimmons/cf-deployer.git`

## Deploy

```sh
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_REGION=
# DOMAIN is the root domain for your foundation
# i.e. the system domain will be 'system.$DOMAIN'
export DOMAIN=

./install_cf.sh
```

Store the following files somewhere safe:

* cf/deployment-vars.yml
* certs/terraform.tfstate
* bosh/*

The credentials for the admin cf account will be:

    Username: admin

    Password: $(bosh interpolate --path /cf_admin_password cf/deployment-vars.yml)

## Destroy

```sh
cd bosh
eval "$(bbl print-env)"
bosh delete-deployment -d cf
bbl destroy \
  --aws-access-key-id "${AWS_ACCESS_KEY_ID}" \
  --aws-secret-access-key "${AWS_SECRET_ACCESS_KEY}" \
  --aws-region "${AWS_REGION}"
```
