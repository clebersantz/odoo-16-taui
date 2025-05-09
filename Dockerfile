FROM python:3.9-slim

ENV LANG C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential python3-dev libxml2-dev libxslt-dev \
    libldap2-dev libsasl2-dev libpq-dev libjpeg-dev zlib1g-dev \
    libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev \
    libpng-dev libtiff5-dev libwebp-dev libffi-dev locales \
    sudo && \
    apt-get clean

# Create odoo user
RUN useradd -m -d /opt/odoo -U -r -s /bin/bash odoo

# Install required Python packages
COPY ./odoo/requirements.txt /
RUN pip3 install -r /requirements.txt

# Set working directory
WORKDIR /opt/odoo

# Copy Odoo & custom addons
COPY --chown=odoo:odoo ./odoo /opt/odoo
COPY --chown=odoo:odoo ./addons /opt/odoo/custom-addons

# Create necessary directories
RUN mkdir -p /var/lib/odoo /var/log/odoo && \
    chown -R odoo:odoo /var/lib/odoo /var/log/odoo

USER odoo

CMD ["./odoo-bin", "-c", "/etc/odoo/odoo.conf"]
