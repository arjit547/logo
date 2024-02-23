#!/bin/bash

if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
    # Installing Git and Git secrets
    echo "Installing Git"
    apt-get update
    apt-get install git -y
    pwd
    ls -al

    echo "Installing Git secrets"
    wget --quiet https://github.com/awslabs/git-secrets/archive/1.3.0.tar.gz
    tar -xzf 1.3.0.tar.gz
    cd git-secrets-1.3.0 && sudo make install && cd ..
    
    # Check if git-secrets is installed successfully
    if ! command -v git-secrets &> /dev/null; then
        echo "Error: git-secrets installation failed."
        exit 1
    fi
    
    git-secrets --register-aws
    git-secrets --scan -r .
    
    # Check if git-secrets scan detects any errors
    if git-secrets --scan -r . | grep -q 'ERROR'; then
        echo "Error: Detected secrets in the repository."
        exit 1
    fi

    # Rest of your deployment script
    if [ -e /home/my-temp-dir/.env ]; then
        echo "Waiting for 2 minutes...."
        sleep 120
        cp -R /home/my-temp-dir/. /var/www/html
        rm -rf /home/my-temp-dir
        chown -R ubuntu:ubuntu /var/www/html
        cd /var/www/html
        npm install
        #npm install -g pkg

        # Run npm build and check its exit code
        npm run build

        if [ $? -ne 0 ]; then
            echo "Error: npm run build failed."
        fi
    else
        cp -R /home/my-temp-dir/. /var/www/html
        rm -rf /home/my-temp-dir
        chown -R ubuntu:ubuntu /var/www/html
        cd /var/www/html
        npm install
        #npm install -g pkg

        # Run npm build and check its exit code
        npm run build

        if [ $? -ne 0 ]; then
            echo "Error: npm run build failed."
        fi
    fi

    # Install SonarQube Scanner globally
    npm install -g sonarqube-scanner@latest

    # Run SonarQube Scanner
    sonar-scanner -Dsonar.projectKey=arjit547_logo -Dsonar.organization=arjit547 -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=9222105b2c25c8770ac2dcde96ffc8c9a979a65c -Dsonar.qualitygate.wait=true
fi
