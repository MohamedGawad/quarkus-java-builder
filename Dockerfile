FROM centos:7

ARG MAVEN_VERSION=3.6.0
ARG GRAAL_VM_VERSION=1.0.0-rc14
ARG USER_HOME_DIR="/root"
ARG SHA=fae9c12b570c3ba18116a4e26ea524b29f7279c17cbaadc3326ca72927368924d9131d11b9e851b8dc9162228b6fdea955446be41207a5cfc61283dd8a561d2f
ARG MAVEN_BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries
ARG GRAAL_VM_BASE_URL=https://github.com/oracle/graal/releases/download/vm-${GRAAL_VM_VERSION}
ARG DEVTOOLS_PKGS="devtoolset-8 llvm-toolset-7"
ARG INSTALL_PKGS="findutils tar gzip zlib-devel openssl-devel"
ARG STATIC_LIBS="glibc-static libcxx libcxx-devel zlib-static"
ARG CONTAINER_TOOLS="buildah podman"
USER root

RUN yum -y install deltarpm \
    && yum -y update \
    && yum install -y centos-release-scl \
    && yum install -y --setopt=tsflags=nodocs $DEVTOOLS_PKGS \
    && yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS \
    && yum -y install -y --setopt=tsflags=nodocs $STATIC_LIBS \
    && yum -y install -y --setopt=tsflags=nodocs $CONTAINER_TOOLS \
    && mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${MAVEN_BASE_URL}/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && mkdir -p /opt/graalvm  \
    && curl -fsSL -o /tmp/graalvm-ce-amd64.tar.gz ${GRAAL_VM_BASE_URL}/graalvm-ce-${GRAAL_VM_VERSION}-linux-amd64.tar.gz \
    && tar -xzf /tmp/graalvm-ce-amd64.tar.gz -C /opt/graalvm --strip-components=1  \
    && yum -y  clean all \
    && rm -rf /var/cache/yum\
    && rm -f /tmp/apache-maven.tar.gz  /tmp/graalvm-ce-amd64.tar.gz \
    && mkdir -p /project


ENV MAVEN_HOME /opt/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV GRAALVM_HOME /opt/graalvm
ENV JAVA_HOME /opt/graalvm

COPY settings.xml /usr/share/maven/ref
ADD ./bin/*.sh /usr/local/bin/

WORKDIR /project

ENTRYPOINT [ "/usr/local/bin/entrypoint-run.sh" ]
CMD [ "mvn","-v" ]