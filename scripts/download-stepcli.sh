#!/bin/sh

set -eux

echo "downloading binary"
wget -qO- https://github.com/smallstep/cli/releases/download/v0.15.3/step_linux_0.15.3_amd64.tar.gz | tar xzOf - step_0.15.3/bin/step > step

echo "verifying integrity"
echo "7ba9ac559ecf556ac753446a918487b6a04a1b46a5672b62b15365be45a100de  step" | sha256sum -c -

echo "making executable" 
chmod +x step
