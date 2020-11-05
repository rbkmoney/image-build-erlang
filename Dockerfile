FROM erlang:22.3.4.12

ENV LANG=C.UTF-8

ENV JAVA_VERSION=jdk8u272-b10
ENV JAVA_HASH='6f124b69d07d8d3edf39b9aa5c58473f63a380b686ddb73a5495e01d25c2939a'

ENV MAVEN_VERSION="3.6.3"
ENV MAVEN_HASH="c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0"

ENV ELVIS_VERSION="0.3.0"
ENV ELVIS_VERSION_HASH="9991522a9b641eafdc29623a24b2b178c88bdf8b"

ENV WOORL_COMMIT="8d955580b4c9161e6afa5012696806a26b2b5e18"
ENV WOORL_COMMIT_HASH="f1c9ac1a5344c1043fff91226ffc015c97d5f4ed"

ENV THRIFT_COMMIT="4c1230a22d137543c62de456c45cda348214b34d"
ENV THRIFT_COMMIT_HASH="35314f4dd706a0e46dc5921d99a711a19d2f2e56"

ENV SWAGGER_CODEGEN_COMMIT="6b410bd4af32cd7580e0a6877e16d76bc9933687"
ENV SWAGGER_CODEGEN_HASH="0256cad1755c711f9bf192440a3cc17f613ba5db"

ENV ELIXIR_VERSION="v1.10.4"
ENV ELIXIR_VERSION_HASH="d8634700f61c72c0e97f1a212919803a86016d2a"

ENV SWAGGER_LIBDIR="/usr/local/lib/swagger-codegen"
ENV SWAGGER_BINDIR="/usr/local/bin"
ENV SWAGGER_JARFILE="swagger-codegen-cli.jar"

RUN set -xe \
    && buildDeps=' \
        flex \
        bison \
        libboost-all-dev \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && mkdir -p /usr/src \

    # Install Java
    && wget -q "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_x64_linux_hotspot_8u272b10.tar.gz" -O /tmp/openjdk.tar.gz \
    && echo "${JAVA_HASH}  /tmp/openjdk.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/java/openjdk \
    && cd /opt/java/openjdk \
    && tar -xf /tmp/openjdk.tar.gz --strip-components=1 \
    && export PATH="/opt/java/openjdk/bin:$PATH" \
    && rm -rf /tmp/openjdk.tar.gz \

    # Install Maven
    && wget -q "https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
        -O /tmp/maven.tar.gz \
    && echo "${MAVEN_HASH}  /tmp/maven.tar.gz" | sha512sum -c - \
    && mkdir -p /opt/maven \
    && cd /opt/maven \
    && tar -xf /tmp/maven.tar.gz --strip-components=1 \
    && export PATH="/opt/maven/bin:$PATH" \
    && rm -rf /tmp/maven.tar.gz \

    # Install thrift
    && mkdir /usr/src/thrift \
    && cd /usr/src/thrift \
    && wget -q "https://github.com/rbkmoney/thrift/archive/${THRIFT_COMMIT}.tar.gz" -O thrift.tar.gz \
    && echo "${THRIFT_COMMIT_HASH}  thrift.tar.gz" | sha1sum -c - \
    && tar xzf thrift.tar.gz --strip-components=1 \
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
    && mkdir /usr/src/woorl \
    && cd /usr/src/woorl \
    && wget -q "https://github.com/rbkmoney/woorl/archive/${WOORL_COMMIT}.tar.gz" -O woorl.tar.gz \
    && echo "${WOORL_COMMIT_HASH}  woorl.tar.gz" | sha1sum -c - \
    && tar xzf woorl.tar.gz --strip-components=1 \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && cp _build/default/bin/woorl /usr/local/bin/ \
    && chmod +x /usr/local/bin/woorl \
    && cd / \
    && rm -rf /usr/src/woorl \

    # Install Elvis
    && mkdir /usr/src/elvis \
    && cd /usr/src/elvis \
    && wget -q "https://github.com/inaka/elvis/archive/${ELVIS_VERSION}.tar.gz" -O elvis.tar.gz \
    && echo "${ELVIS_VERSION_HASH}  elvis.tar.gz" | sha1sum -c - \
    && tar xzf elvis.tar.gz --strip-components=1 \
    && rebar3 escriptize \
    && cp _build/default/bin/elvis /usr/local/bin/ \
    && chmod +x /usr/local/bin/elvis \
    && elvis -v \
    && cd / \
    && rm -rf /usr/src/elvis \

    # Install Elixir
    && mkdir /usr/src/elixir \
    && cd /usr/src/elixir \
    && wget -q "https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" -O elixir.tar.gz \
    && echo "${ELIXIR_VERSION_HASH}  elixir.tar.gz" | sha1sum -c - \
    && tar xzf elixir.tar.gz --strip-components=1 \
    && make install \
    && cd / \
    && rm -rf /usr/src/elixir \

    # Install swagger
    && mkdir -p /usr/src/swagger-codegen \
    && cd /usr/src/swagger-codegen \
    && wget \
        -q \
        "https://github.com/rbkmoney/swagger-codegen/archive/${SWAGGER_CODEGEN_COMMIT}.tar.gz" -O swagger.tar.gz \
    && echo "${SWAGGER_CODEGEN_HASH}  swagger.tar.gz" | sha1sum -c - \
    && tar xzf swagger.tar.gz --strip-components=1 \
    && mvn package -DskipTests \
    && mkdir -p "${SWAGGER_LIBDIR}" "${SWAGGER_BINDIR}" \
    && cp -v "modules/swagger-codegen-cli/target/${SWAGGER_JARFILE}" "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" \
    && test -f "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" || exit 1 \
    && echo '#!/bin/sh\n \
java -jar "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" $*\n' \
        > "${SWAGGER_BINDIR}/swagger-codegen" \
    && chmod +x "${SWAGGER_BINDIR}/swagger-codegen" \
    && cd / \
    && rm -rf /usr/src/swagger-codegen \

    # Cleanup
    && rm -rf /usr/src \
    && rm -rf /root/.m2 \
    && rm -rf /root/.cache \
    && rm -rf /opt/maven \
    && apt-get purge -y --auto-remove $buildDeps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="/opt/java/openjdk/bin:$PATH"
CMD ["bash"]
