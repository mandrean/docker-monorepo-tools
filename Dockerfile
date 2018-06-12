ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS builder
WORKDIR /src

# Install deps & clean up
RUN apk --update --no-cache add \
	git \
	ca-certificates

# Download monorepo-tools and ensure shell scripts executable
# hadolint ignore=DL3003
RUN git config --global user.name "monorepo-tools" && \
	git config --global user.email monorepo-tools@shopsys.com && \
	git clone https://github.com/shopsys/monorepo-tools && \
	cd monorepo-tools && \
	git checkout "${VERSION}" && \
	for file in *.sh; do chmod +x "$file" && mv "$file" "${file%%.sh}" && ln -s "${file%%.sh}" "$file"; done

# Docker multi-stage build
# ref: https://docs.docker.com/engine/userguide/eng-image/multistage-build/#use-multi-stage-builds
FROM alpine:${ALPINE_VERSION} AS runtime

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION
LABEL maintainer="Sebastian Mandrean <sebatian.mandrean@gmail.com>" \
	  # Build-time metadata as defined at http://label-schema.org & https://microbadger.com/labels
	  org.label-schema.build-date="${BUILD_DATE}" \
	  org.label-schema.name="monorepo-tools" \
	  org.label-schema.description="Dockerized Shopsys Monorepo Tools image based on Alpine Linux" \
	  org.label-schema.version="${VERSION}" \
	  org.label-schema.url="https://github.com/mandrean/monorepo-tools" \
	  org.label-schema.vcs-ref="${VCS_REF}" \
	  org.label-schema.vcs-url="${VCS_URL}" \
	  org.label-schema.vendor="Shopsys s.r.o" \
	  org.label-schema.schema-version="1.0"

COPY --from=builder /src/monorepo-tools /usr/local/bin

# Install deps & clean up
RUN apk --update --no-cache add \
		git \
		bash \
		curl \
		sed \
		ca-certificates && \
	apk del wget && \
	rm -rf /var/cache/apk/* /tmp/* && \
	git config --global user.name "monorepo-tools" && \
	git config --global user.email "monorepo-tools@shopsys.com"
