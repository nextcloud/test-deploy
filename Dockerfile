FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y curl procps iputils-ping netcat-traditional && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG BUILD_TYPE
COPY requirements.txt /

ADD /ex_app/cs[s] /ex_app/css
ADD /ex_app/im[g] /ex_app/img
ADD /ex_app/j[s] /ex_app/js
ADD /ex_app/l10[n] /ex_app/l10n
ADD /ex_app/li[b] /ex_app/lib

COPY --chmod=775 healthcheck.sh /
COPY --chmod=775 start.sh /

# Download and install FRP client
RUN set -ex; \
    ARCH=$(uname -m); \
    if [ "$ARCH" = "aarch64" ]; then \
      FRP_URL="https://raw.githubusercontent.com/nextcloud/HaRP/main/exapps_dev/frp_0.61.1_linux_arm64.tar.gz"; \
    else \
      FRP_URL="https://raw.githubusercontent.com/nextcloud/HaRP/main/exapps_dev/frp_0.61.1_linux_amd64.tar.gz"; \
    fi; \
    echo "Downloading FRP client from $FRP_URL"; \
    curl -L "$FRP_URL" -o /tmp/frp.tar.gz; \
    tar -C /tmp -xzf /tmp/frp.tar.gz; \
    mv /tmp/frp_0.61.1_linux_* /tmp/frp; \
    cp /tmp/frp/frpc /usr/local/bin/frpc; \
    chmod +x /usr/local/bin/frpc; \
    rm -rf /tmp/frp /tmp/frp.tar.gz

# Installing PyTorch based on BUILD_TYPE
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        echo "Installing PyTorch for ARM64"; \
        python3 -m pip install torch==2.4.1 torchvision torchaudio; \
    elif [ "$BUILD_TYPE" = "rocm" ]; then \
        python3 -m pip install torch==2.4.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1; \
    elif [ "$BUILD_TYPE" = "cpu" ]; then \
        python3 -m pip install torch==2.4.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu; \
    else \
        python3 -m pip install torch==2.4.1 torchvision torchaudio; \
    fi

RUN \
  python3 -m pip install -r requirements.txt && rm -rf ~/.cache && rm requirements.txt

WORKDIR /ex_app/lib
ENTRYPOINT ["/start.sh"]
HEALTHCHECK --interval=2s --timeout=2s --retries=300 CMD /healthcheck.sh
