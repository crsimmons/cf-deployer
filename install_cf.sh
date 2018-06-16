#!/bin/bash

set -eu

echo "================================================"
echo "Generating self-signed certs for load balancers"
echo "================================================"
pushd certs
terraform init
terraform apply -var "domain=${DOMAIN}" -auto-approve > /dev/null
terraform output -json | jq -r '.bbl_cert.value' > bbl_cert.pem
terraform output -json | jq -r '.bbl_private_key.value' > bbl_key
popd

echo "================================================"
echo "Deploying BOSH director"
echo "================================================"
pushd bosh
bbl plan \
  --lb-type cf \
  --aws-access-key-id "${AWS_ACCESS_KEY_ID}" \
  --aws-secret-access-key "${AWS_SECRET_ACCESS_KEY}" \
  --aws-region "${AWS_REGION}" \
  --iaas aws \
  --lb-cert ../certs/bbl_cert.pem \
  --lb-key ../certs/bbl_key \
  --lb-domain "${DOMAIN}"

bbl up \
  --aws-access-key-id "${AWS_ACCESS_KEY_ID}" \
  --aws-secret-access-key "${AWS_SECRET_ACCESS_KEY}" \
  --aws-region "${AWS_REGION}" \
  --iaas aws

eval "$(bbl print-env)"
popd

echo "================================================"
echo "Uploading stemcell"
echo "================================================"
export IAAS_INFO=aws-xen-hvm
STEMCELL_VERSION=$(bosh interpolate cf-deployment/cf-deployment.yml --path=/stemcells/alias=default/version)
export STEMCELL_VERSION=$STEMCELL_VERSION

bosh upload-stemcell https://bosh.io/d/stemcells/bosh-${IAAS_INFO}-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION}

echo "================================================"
echo "Deploying Cloud Foundry"
echo "================================================"
bosh -d cf deploy cf-deployment/cf-deployment.yml \
  --vars-store cf/deployment-vars.yml \
  -v system_domain="system.${DOMAIN}" \
  -v app_domains="[apps.${DOMAIN}]" \
  -v smoke_test_app_domain="apps.${DOMAIN}" \
  -o cf-deployment/operations/aws.yml \
  -o cf-deployment/operations/use-compiled-releases.yml \
  -o cf-deployment/operations/override-app-domains.yml \
  --non-interactive

echo "================================================"
echo "Deployment Complete"
echo "================================================"

cf_password=$(bosh interpolate --path /cf_admin_password cf/deployment-vars.yml)

echo "Log in to your admin account with:"
echo "cf login -a https://api.system.${DOMAIN} --skip-ssl-validation"
echo "username: admin"
echo "password: ${cf_password}"
