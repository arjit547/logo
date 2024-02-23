#!/bin/bash

# Function to handle deployment failure
deployment_failed() {
    echo "Error: Deployment failed."
    exit 1
}

# Install Git and Git secrets
echo "Installing Git and Git secrets..."
apt-get update && apt-get install git -y
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
if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
    # Copy files to deployment directory
    echo "Deploying to songit deployment group..."
    if [ -e /home/my-temp-dir/.env ]; then
        echo "Waiting for 2 minutes..."
        sleep 120
    fi

    # Copy files and install dependencies
    echo "Copying files to /var/www/html directory..."
    cp -R /home/my-temp-dir/. /var/www/html || deployment_failed
    rm -rf /home/my-temp-dir
    chown -R ubuntu:ubuntu /var/www/html
    cd /var/www/html || deployment_failed
    npm install || deployment_failed

    # Run npm build and check its exit code
    #npm run build || deployment_failed

    # Install SonarQube Scanner globally and run scan
    echo "Installing and running SonarQube Scanner..."
    npm install -g sonarqube-scanner@latest
    sonar-scanner -Dsonar.projectKey=arjit547_logo -Dsonar.organization=arjit547 -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=9222105b2c25c8770ac2dcde96ffc8c9a979a65c -Dsonar.qualitygate.wait=true || deployment_failed
fi

# Deployment successful
echo "Deployment successful."
exit 0
