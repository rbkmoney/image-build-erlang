FROM erlang:24.1.3.0

ENV LANG=C.UTF-8

ENV ELVIS_VERSION="1.0.1"
ENV ELVIS_VERSION_HASH="bfd5eb2de47fc6c8491865b4426e6a329bcfdf95"

ENV WOORL_COMMIT="1da263844344584cdb897371b8fa5fb60b0c3f77"
ENV WOORL_COMMIT_HASH="bf1a28b3041da77517c74834338749ff194424d4"

ENV THRIFT_COMMIT="c6c39e7b377bb36440cbc55d82ee30f8e7e395bc"
ENV THRIFT_COMMIT_HASH="c1c6479200f2c83cac1473a5bb91a3af15d371cb"

ENV SWAGGER_CODEGEN_COMMIT="cedfc45cc4d9d365c03f4f2fe367d8c3893ad509"
ENV SWAGGER_CODEGEN_HASH="726857016e70c770f51598b1b0b12270e9e4a22d"

ENV ELIXIR_VERSION="v1.12.2"
ENV ELIXIR_VERSION_HASH="b525e7357b939156915580de0a5db8162a123ede"

ENV SWAGGER_LIBDIR="/usr/local/lib/swagger-codegen"
ENV SWAGGER_BINDIR="/usr/local/bin"
ENV SWAGGER_JARFILE="swagger-codegen-cli.jar"

RUN set -xe \
    && fetchDeps=' \
        software-properties-common \
    ' \
    && buildDeps=' \
        flex \
        bison \
        libboost-dev \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $fetchDeps $buildDeps \
    && apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main' \
    && apt-get update \
    && apt-get install -y --no-install-recommends openjdk-8-jdk-headless \
    && apt-get install -y --no-install-recommends maven linux-perf valgrind \
    && mkdir -p /usr/src

#
# Install thrift
#
RUN mkdir /usr/src/thrift \
    && cd /usr/src/thrift \
    && wget -q "https://github.com/rbkmoney/thrift/archive/${THRIFT_COMMIT}.tar.gz" -O thrift.tar.gz \
    && echo "${THRIFT_COMMIT_HASH}  thrift.tar.gz" | sha1sum -c - \
    && tar xzf thrift.tar.gz --strip-components=1 \
    && ./bootstrap.sh \
    && ./configure \
        --disable-dependency-tracking \
        --with-erlang \
        --without-cpp \
        --without-java \
        --disable-tutorial \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && cd / \
    && rm -rf /usr/src/thrift

#
# Install woorl
#
RUN mkdir /usr/src/woorl \
    && cd /usr/src/woorl \
    && wget -q "https://github.com/rbkmoney/woorl/archive/${WOORL_COMMIT}.tar.gz" -O woorl.tar.gz \
    && echo "${WOORL_COMMIT_HASH}  woorl.tar.gz" | sha1sum -c - \
    && tar xzf woorl.tar.gz --strip-components=1 \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && cp _build/default/bin/woorl /usr/local/bin/ \
    && chmod +x /usr/local/bin/woorl \
    && cd / \
    && rm -rf /usr/src/woorl

#
# Install Elvis
#
RUN mkdir /usr/src/elvis \
    && cd /usr/src/elvis \
    && wget -q "https://github.com/inaka/elvis/archive/${ELVIS_VERSION}.tar.gz" -O elvis.tar.gz \
    && echo "${ELVIS_VERSION_HASH}  elvis.tar.gz" | sha1sum -c - \
    && tar xzf elvis.tar.gz --strip-components=1 \
    && rebar3 escriptize \
    && cp _build/default/bin/elvis /usr/local/bin/ \
    && chmod +x /usr/local/bin/elvis \
    && elvis -v \
    && cd / \
    && rm -rf /usr/src/elvis

#
# Install Elixir
#
RUN mkdir /usr/src/elixir \
    && cd /usr/src/elixir \
    && wget -q "https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" -O elixir.tar.gz \
    && echo "${ELIXIR_VERSION_HASH}  elixir.tar.gz" | sha1sum -c - \
    && tar xzf elixir.tar.gz --strip-components=1 \
    && make install clean \
    && cd / \
    && rm -rf /usr/src/elixir

#
# Install swagger
#
RUN mkdir -p /usr/src/swagger-codegen \
    && cd /usr/src/swagger-codegen \
    && wget -q "https://github.com/rbkmoney/swagger-codegen/archive/${SWAGGER_CODEGEN_COMMIT}.tar.gz" -O swagger.tar.gz \
    && echo "${SWAGGER_CODEGEN_HASH}  swagger.tar.gz" | sha1sum -c - \
    && tar xzf swagger.tar.gz --strip-components=1 \
    && mvn package -DskipTests \
    && mkdir -p "${SWAGGER_LIBDIR}" "${SWAGGER_BINDIR}" \
    && cp -v "modules/swagger-codegen-cli/target/${SWAGGER_JARFILE}" "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" \
    && test -f "${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}" || exit 1 \
    && echo "#!/bin/sh" > "${SWAGGER_BINDIR}/swagger-codegen" \
    && echo "java -jar \"${SWAGGER_LIBDIR}/${SWAGGER_JARFILE}\" \$*" >> "${SWAGGER_BINDIR}/swagger-codegen" \
    && chmod +x "${SWAGGER_BINDIR}/swagger-codegen" \
    && cd / \
    && rm -rf /usr/src/swagger-codegen

#
# Cleanup
#
RUN rm -rf /usr/src \
    && rm -rf /root/.m2 \
    && rm -rf /root/.cache \
    && apt-get purge -y --auto-remove $fetchDeps $buildDeps \
    && apt-get clean \
    && rm -rf $ERL_TOP /var/lib/apt/lists/*

#
# Default bash
#
RUN echo "dash dash/sh boolean false" | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash \
    && sed -i "s|SHELL=/bin/sh|SHELL=/bin/bash|g" /etc/default/useradd

CMD ["bash"]
