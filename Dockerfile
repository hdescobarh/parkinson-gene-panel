# #### Base image  ####

FROM python:3.13.7-trixie AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
PYTHONUNBUFFERED=1 \
PIP_NO_CACHE_DIR=1 \
PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt update && apt install jq tmux -y \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /panel
RUN touch /panel/requirements.txt

EXPOSE 8888

# #### Development image  ####

FROM base AS development

COPY pyproject.toml .

# I am aware using venv inside containers can be considered redundant.
# However, accepting a slight increase in image size in exchange for
# consistency and protection against potential corner cases leads to a
# net reduction in overall complexity.

RUN python -m venv "/dev_venv"
ENV PATH="/dev_venv/bin:$PATH"

RUN pip install pip-tools && \
pip-compile --extra dev --strip-extras -o "./requirements.txt" "./pyproject.toml"
# Maximizing reproducibility. Lock dependencies in build environment.
ENV PIP_CONSTRAINT="/panel/requirements.txt"
RUN pip-sync "./requirements.txt"
ENV PYTHONPATH="/panel/src:$PYTHONPATH"

ENV SHELL=/bin/bash
RUN echo 'eval "$(/bin/dircolors)"' >> /root/.bashrc && \
    echo 'alias ls="ls --color=auto"' >> /root/.bashrc && \
    echo 'alias grep="grep --color=auto"' >> /root/.bashrc && \
    echo 'PS1="\[\e]0;\u@\h: \W\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]# "\n' >> /root/.bashrc
