# #### Base image  ####

FROM python:3.13.7-trixie AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
PYTHONUNBUFFERED=1 \
PIP_NO_CACHE_DIR=1 \
PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /panel
RUN apt update && apt install jq -y \
&& rm -rf /var/lib/apt/lists/*

EXPOSE 8888


# #### Production image  ####

FROM base AS production

# Named after Margaret Oakley Dayhoff, the "mother and father of bioinformatics."
RUN adduser --disabled-password --gecos '' margaret

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY makefile .
COPY config/ ./config/
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY notebooks/ ./notebooks/

RUN chmod 755 scripts/*.sh
RUN chown -R margaret:margaret /panel

USER margaret

# #### Development image  ####

FROM base AS development

COPY pyproject.toml .
RUN pip install pip-tools && \
pip-compile --extra dev pyproject.toml && \
pip install -r requirements.txt

ENV PYTHONPATH=/panel/src:$PYTHONPATH
CMD ["jupyter", "lab", "--notebook-dir=./notebooks", "--ip=0.0.0.0", "--port=8888", "--ServerApp.token=", "--ServerApp.password=", "--allow-root"]
