#!/bin/bash

# Install Git and Git secrets
echo "Installing Git and Git secrets..."
apt-get update
apt-get install git -y
wget --quiet https://github.com/awslabs/git-secrets/archive/1.3.0.tar.gz
tar -xzf 1.3.0.tar.gz
cd git-secrets-1.3.0 && sudo make install && cd ..
git secrets --register-aws

# Scan the repository for secrets
echo "Scanning repository for secrets..."
if git secrets --scan -r . | grep -q 'ERROR'; then
    echo "Error: Secrets found. Deployment failed."
    exit 1
fi

# Proceed with deployment steps

# Deployment logic for "songit" deployment group
if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
    # Check if .env file exists
    if [ -e /home/my-temp-dir/.env ]; then
        echo "Waiting for 2 minutes..."
        sleep 120
    fi

    # Copy files to deployment directory
    echo "Deploying to songit deployment group..."
    cp -R /home/my-temp-dir/. /var/www/html
    rm -rf /home/my-temp-dir
    chown -R ubuntu:ubuntu /var/www/html
    cd /var/www/html || exit 1

    # Install dependencies and build
    npm install && npm run build
    if [ $? -ne 0 ]; then
        echo "Error: npm install or npm run build failed."
        exit 1
    fi

    # Install SonarQube Scanner and run scan
    npm install -g sonarqube-scanner@latest
    sonar-scanner -Dsonar.projectKey=arjit547_logo -Dsonar.organization=arjit547 -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=9222105b2c25c8770ac2dcde96ffc8c9a979a65c -Dsonar.qualitygate.wait=true
fi

# Additional deployment steps common to all deployment groups
echo "Additional deployment steps..."
# Add any other deployment steps here

echo "Deployment successful."
exit 0
