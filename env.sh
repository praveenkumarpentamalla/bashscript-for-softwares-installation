#!/bin/bash
echo 'export WEB_ENV="test"' >> /etc/bash.bashrc

echo 'export projectname="projectname"' >> /etc/bash.bashrc
echo 'export SECRET_KEY "<token>"' >> /etc/bash.bashrc

echo 'export DRF_API_LOGGER_DATABASE=True' >> /etc/bash.bashrc

# TEST DATABASE CONNECTION PARAMETERS
# echo 'export STAGING_DATABASE_NAME=""' >> /etc/bash.bashrc
# echo 'export STAGING_DATABASE_USER=""' >> /etc/bash.bashrc
# echo 'export STAGING_DATABASE_PASSWORD=""' >> /etc/bash.bashrc
# echo 'export STAGING_DATABASE_HOST=""' >> /etc/bash.bashrc
# echo 'export STAGING_DATABASE_ENGINE=""' >> /etc/bash.bashrc
