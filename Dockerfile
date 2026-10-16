# SPDX-FileCopyrightText: 2025 SAP SE or an SAP affiliate company
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.27.2-alpine3.24@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d AS builder

WORKDIR /src
COPY . .

# Static binary from vendored modules, no toolchain or module downloads at build time
ARG BININFO_BUILD_DATE BININFO_COMMIT_HASH BININFO_VERSION
RUN CGO_ENABLED=0 GOOS=linux GOTOOLCHAIN=local \
    go build -mod vendor \
    -ldflags "-w -s \
              -X github.com/sapcc/go-api-declarations/bininfo.binName=kubernetes-oomkill-exporter \
              -X github.com/sapcc/go-api-declarations/bininfo.buildDate=${BININFO_BUILD_DATE} \
              -X github.com/sapcc/go-api-declarations/bininfo.commit=${BININFO_COMMIT_HASH} \
              -X github.com/sapcc/go-api-declarations/bininfo.version=${BININFO_VERSION}" \
    -o /kubernetes-oomkill-exporter .

# distroless static already ships CA certificates
FROM gcr.io/distroless/static-debian12@sha256:d75cdd72874d4790092fcb1b058493ecf6bb5bf2b2b897045b00ff01d91843f2

COPY --from=builder /kubernetes-oomkill-exporter /usr/bin/kubernetes-oomkill-exporter

# Verify binary works
RUN ["/usr/bin/kubernetes-oomkill-exporter", "--version"]

WORKDIR /
ENTRYPOINT ["/usr/bin/kubernetes-oomkill-exporter"]
