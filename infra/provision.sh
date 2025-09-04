#!/usr/bin/env bash

workload_name="hugo-static-app"
region=westeurope

resource_group_name=$(printf "rg-%s" "$workload_name")
static_web_app_name=$(printf "stapp-%s" "$workload_name")
static_web_app_sku="Free"

az group create \
  --name "$resource_group_name" \
  --location $region

az staticwebapp create \
  --name "$static_web_app_name" \
  --resource-group "$resource_group_name" \
  --location $region \
  --source "$(git remote -v | awk '/push/{print $2}')" \
  --app-location "/" \
  --output-location "public" \
  --branch "main" \
  --sku "$static_web_app_sku" \
  --login-with-github

webapp_url=$(az staticwebapp show --name "$static_web_app_name" --resource-group "$resource_group_name" --query "defaultHostname" -o tsv)

runtime="+1M"
endtime=$(date -v${runtime} +%s)

while [[ $(date +%s) -le $endtime ]]; do
  if curl -I -s "$webapp_url" >/dev/null; then
    curl -L -s "$webapp_url" 2>/dev/null | head -n 9
    break
  else
    sleep 10
  fi
done

echo "You can now visit your web server at https://$webapp_url"
echo
echo "The rendered page will be visible as soon as the workflow action has been run successfull"
echo "See $(git remote -v | awk '/push/{print $2}')/actions"
