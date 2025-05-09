# Create project directory
mkdir odoo16-prod && cd odoo16-prod

# Clone Odoo 16 source
git clone --depth --branch 16.0 https://github.com/odoo/odoo.git odoo

# Create addons directory & clone OCA modules
mkdir addons
cd addons
git clone --depth 1 --branch 16.0 https://github.com/OCA/l10n-brazil.git
git clone --depth 1 --branch 16.0 https://github.com/OCA/account-financial-tools.git
cd ..
