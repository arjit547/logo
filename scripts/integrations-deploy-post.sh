#!/bin/bash

# Check if the deployment group is 'songit'
if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
    # Install Git and Git secrets
    echo "Installing Git"
    apt-get update
    apt-get install git -y

    echo "Installing Git secrets"
    wget --quiet https://github.com/awslabs/git-secrets/archive/1.3.0.tar.gz
    tar -xzf 1.3.0.tar.gz
    cd git-secrets-1.3.0 && sudo make install && cd ..
    git-secrets --register-aws

    # Scan the repository for secrets
    echo "Scanning repository for secrets"
    git-secrets --scan -r .

    # Check Git secrets scan exit code
    if git-secrets --scan -r . | grep -q 'ERROR'; then
        echo "Error: Secrets found in the repository. Aborting deployment."
        exit 1
    else
        echo "No secrets found in the repository. Proceeding with deployment."
    fi

    # Copy files to destination
    if [ -e /home/my-temp-dir/.env ]; then
        echo "Waiting for 2 minutes...."
        sleep 120
    fi

    echo "Copying files to destination..."
    cp -R /home/my-temp-dir/. /var/www/html
    rm -rf /home/my-temp-dir
    chown -R ubuntu:ubuntu /var/www/html
    cd /var/www/html

    # Install npm dependencies
    echo "Installing npm dependencies..."
    npm install

    # Check npm install exit code
    if [ $? -ne 0 ]; then
        echo "Error: npm install failed."
        exit 1
    fi
fi
