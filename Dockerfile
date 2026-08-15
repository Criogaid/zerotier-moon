ARG ALPINE_VERSION=3.24
FROM alpine:${ALPINE_VERSION} AS builder

ARG TAG=main
WORKDIR /src/ZeroTierOne

# ZeroTierOne 仅在这些平台构建 Rust SSO 组件。
RUN apk add --no-cache build-base git linux-headers openssl-dev \
    && case "$(apk --print-arch)" in x86|x86_64|aarch64) apk add --no-cache cargo ;; esac
RUN git clone --depth 1 --branch "$TAG" https://github.com/zerotier/ZeroTierOne.git .
RUN make -j"$(nproc)" CPPFLAGS+=-w \
    && strip zerotier-one

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache ipcalc jq libgcc libssl3 libstdc++ \
    && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
    && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool

COPY --from=builder /src/ZeroTierOne/zerotier-one /usr/sbin/zerotier-one
RUN /usr/sbin/zerotier-one -v
COPY --chmod=755 startup.sh /usr/bin/startup.sh
COPY --chmod=755 healthcheck.sh /healthcheck.sh

EXPOSE 9993/udp
VOLUME /var/lib/zerotier-one

HEALTHCHECK --interval=1s CMD ["/healthcheck.sh"]
ENTRYPOINT ["/usr/bin/startup.sh"]
