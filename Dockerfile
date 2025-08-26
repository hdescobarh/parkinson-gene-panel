# ### Build stage ###

FROM python:3.13.7-trixie AS builder

ENV BEDOPS_VERSION="2.4.42"
ENV BEDOPS_SHA256="3a8b4961ff80e201e2a286b91c7a0ee8fff6387ab44c3fc07c3765fdf9aedfef"

WORKDIR /tmp

# Despite the bedops release suffix, the file is actually a tar. Check with `file` command.
RUN curl -L -o "bedops.tar.bz2" \
  "https://github.com/bedops/bedops/releases/download/v${BEDOPS_VERSION}/bedops_linux_x86_64-v${BEDOPS_VERSION}.tar.bz2" \
  && echo "${BEDOPS_SHA256} bedops.tar.bz2" | sha256sum -c - \
  && tar -xf "bedops.tar.bz2" \
  && chmod +x bin/*


# ### Runtime stage ###

FROM python:3.13.7-trixie AS production

ENV PYTHONDONTWRITEBYTECODE=1 \
PYTHONUNBUFFERED=1 \
PIP_NO_CACHE_DIR=1 \
PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt update && apt install jq -y && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/bin/* /usr/local/bin/

WORKDIR /panel

COPY pyproject.toml requirements.txt makefile /panel/
COPY README.md LICENSE* NOTICE /panel/
COPY src/ /panel/src/
COPY scripts/ /panel/scripts/
COPY notebooks/ /panel/notebooks/
COPY config/ /panel/config/

VOLUME ["/panel/data"]
VOLUME ["/panel/reports"]
VOLUME ["/panel/logs"]
VOLUME ["/panel/.stamps"]

RUN make init

EXPOSE 8888
ENTRYPOINT ["make"]
CMD ["jupyter-root"]
