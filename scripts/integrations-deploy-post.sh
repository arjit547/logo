#!/bin/bash

if [ "$DEPLOYMENT_GROUP_NAME" == "songit" ]; then
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
        #npm run build

        if [ $? -ne 0 ]; then
            echo "Error: npm run build failed."
        fi
    else
        cp -R /home/my-temp-dir/. /var/www/html
        rm -rf /home/my-temp-dir
        chown -R ubuntu:ubuntu /var/www/html
        cd /var/www/html
        npm install

        # Run npm build and check its exit code
        #npm run build

        if [ $? -ne 0 ]; then
            echo "Error: npm run build failed."
        fi
    fi

    # Installing Git and Git secrets
    echo "Installing Git"
    apt-get update
    apt-get install git -y

    echo "Installing Git secrets"
    wget --quiet https://github.com/awslabs/git-secrets/archive/1.3.0.tar.gz
    tar -xzf 1.3.0.tar.gz
    cd git-secrets-1.3.0 && sudo make install && cd ..
    git-secrets --register-aws
    git-secrets --scan -r .
    if git-secrets --scan -r . | grep -q 'ERROR'; then
        exit 1
    fi

fi
