#!/bin/bash
set -euo pipefail

# ============================================================
# Azure Container Apps + PostgreSQL セットアップスクリプト
# 使い方:
#   cp .env.azure.example .env.azure
#   # .env.azure を編集
#   bash setup.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$SCRIPT_DIR/.env.azure" ]; then
  echo "ERROR: .env.azure が見つかりません。"
  echo "  cp .env.azure.example .env.azure して編集してください。"
  exit 1
fi

source "$SCRIPT_DIR/.env.azure"

echo "=== 1/6 リソースグループ作成 ==="
az group create \
  --name "$AZURE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION"

echo "=== 2/6 Container Registry (Basic) 作成 ==="
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

echo "=== 3/6 PostgreSQL Flexible Server (B1ms) 作成 ==="
az postgres flexible-server create \
  --name "$PG_SERVER_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION" \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --version 16 \
  --admin-user "$PG_ADMIN_USER" \
  --admin-password "$PG_ADMIN_PASSWORD" \
  --yes

echo "=== 3.1 データベース作成 (4個) ==="
for DB_NAME in dxceco_poc_production dxceco_poc_production_cache dxceco_poc_production_queue dxceco_poc_production_cable; do
  echo "  Creating $DB_NAME..."
  az postgres flexible-server db create \
    --server-name "$PG_SERVER_NAME" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --database-name "$DB_NAME"
done

echo "=== 3.2 PostgreSQL ファイアウォール: Azure サービス許可 ==="
az postgres flexible-server firewall-rule create \
  --name "$PG_SERVER_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

echo "=== 4/6 Container Apps 環境作成 ==="
az containerapp env create \
  --name "$CONTAINER_APP_ENV" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION"

echo "=== 5/6 ACR 認証情報取得 ==="
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)

# DATABASE_URL の組み立て
PG_HOST="${PG_SERVER_NAME}.postgres.database.azure.com"
DATABASE_URL="postgres://${PG_ADMIN_USER}:${PG_ADMIN_PASSWORD}@${PG_HOST}:5432/dxceco_poc_production?sslmode=require"

echo "=== 6/6 Container App 作成 ==="
az containerapp create \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --environment "$CONTAINER_APP_ENV" \
  --image "${ACR_LOGIN_SERVER}/dxceco-poc:latest" \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username "$ACR_NAME" \
  --registry-password "$ACR_PASSWORD" \
  --target-port 80 \
  --ingress external \
  --cpu 0.25 \
  --memory 0.5Gi \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars \
    "RAILS_ENV=production" \
    "RAILS_MASTER_KEY=${RAILS_MASTER_KEY}" \
    "DATABASE_URL=${DATABASE_URL}" \
    "DXCECO_POC_DATABASE_PASSWORD=${PG_ADMIN_PASSWORD}" \
    "PGPORT=5432" \
    "APP_URL=${APP_URL}" \
    "ENTRA_CLIENT_ID=${ENTRA_CLIENT_ID}" \
    "ENTRA_CLIENT_SECRET=${ENTRA_CLIENT_SECRET}" \
    "ENTRA_TENANT_ID=${ENTRA_TENANT_ID}" \
    "SOLID_QUEUE_IN_PUMA=true"

echo ""
echo "============================================================"
echo "セットアップ完了!"
echo ""
APP_FQDN=$(az containerapp show --name "$CONTAINER_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv)
echo "アプリURL: https://${APP_FQDN}"
echo "ACR:       ${ACR_LOGIN_SERVER}"
echo ""
echo "次のステップ:"
echo "  1. Docker イメージをビルド & プッシュ:"
echo "     az acr login --name ${ACR_NAME}"
echo "     docker build -t ${ACR_LOGIN_SERVER}/dxceco-poc:latest ."
echo "     docker push ${ACR_LOGIN_SERVER}/dxceco-poc:latest"
echo ""
echo "  2. Container App を更新:"
echo "     az containerapp update --name ${CONTAINER_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --image ${ACR_LOGIN_SERVER}/dxceco-poc:latest"
echo ""
echo "  3. Entra ID にリダイレクトURI追加:"
echo "     https://${APP_FQDN}/auth/entra_id/callback"
echo "============================================================"
