FROM jenkins/jenkins:2.519-jdk21
USER root

# Установка Docker CLI
RUN apt-get update && \
    apt-get install -y lsb-release curl && \
    curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Установка kubectl
RUN apt-get update && apt-get install -y curl && \
    curl -LO https://dl.k8s.io/release/v1.33.3/bin/linux/amd64/kubectl && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl


USER jenkins

# Установка плагинов и зависимостей
RUN jenkins-plugin-cli --plugins \
    basic-branch-build-strategies \
    blueocean \
    dark-theme \
    docker-workflow \
    favorite \
    git \
    github \
    json-path-api \
    pipeline-github-lib \
    theme-manager \
    token-macro