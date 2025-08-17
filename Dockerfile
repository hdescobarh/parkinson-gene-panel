# #### Base image  ####

FROM python:3.11.7-trixie as base

WORKDIR /panel
EXPOSE 8888

# #### Production image  ####

FROM base as production

# Named after Margaret Oakley Dayhoff, the "mother and father of bioinformatics."
RUN adduser --disabled-password --gecos '' margaret

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY makefile .
COPY config/ ./config/
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY notebooks/ ./notebooks/

RUN chmod 755 scripts/*.sh
RUN chown -R margaret:margaret /panel

USER margaret

# #### Development image  ####

FROM base as development

COPY pyproject.toml .
RUN pip install -e .[env]
