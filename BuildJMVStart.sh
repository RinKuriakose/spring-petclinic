```
#!/bin/bash

set -e

docker compose build jenkins
docker compose build maven-java25
docker images | grep -E "jenkins|maven-java25" || {
    echo "ERROR: Jenkins or Maven-Java25 image failed."
    exit 1
}

docker compose up -d
```
