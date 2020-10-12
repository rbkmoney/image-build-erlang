FROM erlang:22.3.4.11-alpine

ENV ELVIS_VERSION="0.3.0"
ENV WOORL_COMMIT="8d955580b4c9161e6afa5012696806a26b2b5e18"
ENV THRIFT_COMMIT="4c1230a22d137543c62de456c45cda348214b34d"
ENV SWAGGER_CODEGEN_COMMIT="6b410bd4af32cd7580e0a6877e16d76bc9933687"
ENV ELIXIR_VERSION="v1.10.4"
ENV LANG=C.UTF-8

ENV SWAGGER_LIBDIR="/usr/local/lib/swagger-codegen"
ENV SWAGGER_BINDIR="/usr/local/bin"
ENV SWAGGER_JARFILE="swagger-codegen-cli.jar"

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        g++ \
        make \
        autoconf \
        automake \
        git \
        bison \
        boost-dev \
        boost-static \
        flex \
        libevent-dev \
        libtool \
        openssl-dev \
        zlib-dev \
        openjdk8 \
        maven \
    && mkdir -p /usr/src \

    # Install thrift
    && git clone https://github.com/rbkmoney/thrift.git /usr/src/thrift \
    && cd /usr/src/thrift \
    && git checkout "${THRIFT_COMMIT}" \
    && ./bootstrap.sh \
    && ./configure \
        --disable-dependency-tracking \
        --with-erlang \
        --without-cpp \
        --disable-tutorial \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && cd / \
    && rm -rf /usr/src/thrift \

    # Install woorl
    && git clone https://github.com/rbkmoney/woorl /usr/src/woorl \
    && cd /usr/src/woorl \
    && git checkout "${WOORL_COMMIT}" \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && cp _build/default/bin/woorl /usr/local/bin/ \
    && chmod +x /usr/local/bin/woorl \
    && cd / \
    && rm -rf /usr/src/woorl \

    # Install Elvis
    && mkdir /usr/src/elvis \
    && cd /usr/src/elvis \
    && wget -q "https://github.com/inaka/elvis/archive/${ELVIS_VERSION}.tar.gz" \
        -O - | tar xz --strip-components=1 \
    && rebar3 escriptize \
    && cp _build/default/bin/elvis /usr/local/bin/ \
    && chmod +x /usr/local/bin/elvis \
    && elvis -v \
    && cd / \
    && rm -rf /usr/src/elvis \

    # Install Elixir
    && mkdir /usr/src/elixir \
    && cd /usr/src/elixir \
    && wget -q "https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
        -O - | tar xz --strip-components=1 \
    && make install \
    && cd / \
    && rm -rf /usr/src/elixir \

    # Install swagger
    && mkdir -p /usr/src/swagger-codegen \
    && cd /usr/src/swagger-codegen \
    && wget \
        -q \
        "https://github.com/rbkmoney/swagger-codegen/archive/${SWAGGER_CODEGEN_COMMIT}.tar.gz" \
	 -O - | tar xz --strip-components=1 \
    && mvn package -DskipTests \
    && mkdir -p "${SWAGGER_LIBDIR}" "${SWAGGER_BINDIR}" \
    && cp -v "modules/swagger-codegen-cli/target/${SWAGGER_JARFILE}" "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" \
    && test -f "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" || exit 1 \
    && echo $'#/bin/sh\n \
java -jar "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" $*\n' \
        > "${SWAGGER_BINDIR}/swagger-codegen" \
    && chmod +x "${SWAGGER_BINDIR}/swagger-codegen" \
    && cd / \
    && rm -rf /usr/src/swagger-codegen \

    # Cleanup
    && rm -rf /usr/src \
    && rm -rf /root/.m2 \
    && rm -rf /root/.cache \
    && scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
	&& scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
    && apk add --no-cache --virtual .build-rundeps \
		$runDeps \
        openjdk8-jre-base \
        make \
        bash \
        shadow \
        git \
        gcc \
        python2 \
        g++ \
        openssh-client \
        coreutils \
    && apk --no-cache del .build-deps \
    && rm /var/cache/apk/*

CMD ["sh"]
