#!/bin/bash

# Function to check if git-secret is installed
check_git_secret_installed() {
    if ! command -v git-secret &> /dev/null; then
        echo "Error: git-secret is not installed. Aborting deployment."
        exit 1
    fi
}

# Check if the deployment group is 'songit'
if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
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

    # Installing Git and Git secrets
    echo "Installing Git"
    apt-get update
    apt-get install git -y

    check_git_secret_installed  # Check if git-secret is installed

    echo "Installing Git secrets"
    wget --quiet https://github.com/awslabs/git-secrets/archive/1.3.0.tar.gz
    tar -xzf 1.3.0.tar.gz
    cd git-secrets-1.3.0 && sudo make install && cd ..
    git-secrets --register-aws
    git-secrets --scan -r .

    # Check Git secrets scan exit code
    if git-secrets --scan -r . | grep -q 'ERROR'; then
        echo "Error: Secrets found in the repository. Aborting deployment."
        exit 1
    else
        echo "No secrets found in the repository."
    fi
fi
