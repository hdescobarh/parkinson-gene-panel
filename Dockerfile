# #### Base image  ####

FROM python:3.13.7-trixie AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
PYTHONUNBUFFERED=1 \
PIP_NO_CACHE_DIR=1 \
PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /panel
RUN apt update && apt install jq tmux -y \
&& rm -rf /var/lib/apt/lists/*

EXPOSE 8888

# #### Development image  ####

FROM base AS development

COPY pyproject.toml .
RUN pip install pip-tools && \
pip-compile --extra dev pyproject.toml && \
pip install -r requirements.txt

ENV PYTHONPATH=/panel/src:$PYTHONPATH
