#!/bin/bash

ODOO_VERSION="16.0"
ODOO_USER="odoo16"
ODOO_ROOT="/opt/odoo16"
ODOO_HOME="$ODOO_ROOT/odoo"
ODOO_OCA="$ODOO_ROOT/addons"
ODOO_VENV="$ODOO_ROOT/venv"
ODOO_CONF="/etc/odoo.conf"
ODOO_PORT=8069

echo "===> Atualizando pacotes"
sudo apt update && sudo apt upgrade -y

echo "===> Instalando dependências básicas"
sudo apt install -y software-properties-common curl

echo "===> Adicionando PPA do Python 3.9 (deadsnakes)"
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.9 python3.9-venv python3.9-dev

echo "===> Instalando pacotes do sistema"
sudo apt install -y git build-essential wget \
libxslt-dev libzip-dev libldap2-dev libsasl2-dev \
libjpeg-dev zlib1g-dev libpq-dev libxml2-dev libffi-dev \
libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev \
supervisor postgresql

echo "===> Criando usuário $ODOO_USER"
sudo useradd -m -d $ODOO_ROOT -U -r -s /bin/bash $ODOO_USER

echo "===> Criando banco de dados PostgreSQL"
sudo -u postgres createuser --superuser $ODOO_USER

echo "===> Clonando Odoo em $ODOO_HOME"
sudo -u $ODOO_USER mkdir -p $ODOO_HOME
sudo -u $ODOO_USER git clone https://github.com/odoo/odoo.git --depth 1 --branch $ODOO_VERSION $ODOO_HOME

echo "===> Criando ambiente virtual Python em $ODOO_VENV"
sudo -u $ODOO_USER python3.9 -m venv $ODOO_VENV
sudo -u $ODOO_USER $ODOO_VENV/bin/pip install wheel
sudo -u $ODOO_USER $ODOO_VENV/bin/pip install -r $ODOO_HOME/requirements.txt

echo "===> Criando diretório de logs"
sudo mkdir -p /var/log/odoo
sudo chown $ODOO_USER:$ODOO_USER /var/log/odoo

echo "===> Clonando repositórios OCA em $ODOO_OCA"
sudo -u $ODOO_USER mkdir -p $ODOO_OCA
cd $ODOO_OCA

REPOS=(
  account-financial-tools
  account-financial-reporting
  account-reconcile
  bank-payment
  reporting-engine
  account-budgeting
  l10n-brazil
  mis-builder
  contract
  web
  server-ux
  bank-statement-import
  purchase-workflow
  account_bank_statement_import
  account-payment
)

for repo in "${REPOS[@]}"; do
  echo "===> Clonando $repo"
  sudo -u $ODOO_USER git clone --depth 1 -b $ODOO_VERSION https://github.com/OCA/$repo.git
done

# Monta o addons_path com os caminhos dos repositórios clonados
ADDONS_PATHS="$ODOO_HOME/addons"
for repo in "${REPOS[@]}"; do
  ADDONS_PATHS="$ADDONS_PATHS,$ODOO_OCA/$repo"
done

echo "===> Criando arquivo de configuração $ODOO_CONF"
sudo tee $ODOO_CONF > /dev/null <<EOF
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ADDONS_PATHS
logfile = /var/log/odoo/odoo.log
xmlrpc_port = $ODOO_PORT
EOF

sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONF
sudo chmod 640 $ODOO_CONF

echo "===> Configurando Supervisor"
sudo tee /etc/supervisor/conf.d/odoo.conf > /dev/null <<EOF
[program:odoo]
command=$ODOO_VENV/bin/python3 $ODOO_HOME/odoo-bin -c $ODOO_CONF
directory=$ODOO_HOME
user=$ODOO_USER
autostart=true
autorestart=true
stderr_logfile=/var/log/odoo/odoo_error.log
stdout_logfile=/var/log/odoo/odoo.log
EOF

echo "===> Ativando Supervisor"
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start odoo

echo "===> Instalação concluída com sucesso!"
echo "Acesse o Odoo em: http://<IP_DO_SERVIDOR>:$ODOO_PORT"
