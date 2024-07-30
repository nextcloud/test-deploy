FROM python:3.11-slim-bookworm

ARG BUILD_TYPE
COPY requirements.txt /

ADD cs[s] /app/css
ADD im[g] /app/img
ADD j[s] /app/js
ADD l10[n] /app/l10n
ADD li[b] /app/lib

COPY --chmod=775 healthcheck.sh /

# Installing PyTorch based on BUILD_TYPE
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        echo "Installing PyTorch for ARM64"; \
        python3 -m pip install torch torchvision torchaudio; \
    elif [ "$BUILD_TYPE" = "rocm" ]; then \
        python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1; \
    elif [ "$BUILD_TYPE" = "cpu" ]; then \
        python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu; \
    else \
        python3 -m pip install torch torchvision torchaudio; \
    fi

RUN \
  python3 -m pip install -r requirements.txt && rm -rf ~/.cache && rm requirements.txt

WORKDIR /app/lib
ENTRYPOINT ["python3", "main.py"]
HEALTHCHECK --interval=2s --timeout=2s --retries=300 CMD /healthcheck.sh
