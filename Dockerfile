FROM imranq2/spark-py:3.0.1
USER root

ENV PYTHONPATH=/helix.pipelines:/usr/local/lib/python3.7/dist-packages
ENV CLASSPATH=/helix.pipelines/jars:$CLASSPATH

RUN echo "deb-src http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

ENV PYSPARK_MAJOR_PYTHON_VERSION=3

RUN apt update && apt build-dep -y python3 && apt install git -y && git --version && apt-get clean

RUN apt-get update \
 && apt-get install -y curl unzip \
    python3 python3-setuptools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN ls /usr/bin/

RUN pip3 install --upgrade --no-cache-dir pip && \
    pip3 install --no-cache-dir wheel && \
    pip3 install --no-cache-dir pre-commit && \
    pip3 install --no-cache-dir pipenv

COPY Pipfile* /helix.pipelines/

WORKDIR /helix.pipelines

#COPY ./jars/* /opt/bitnami/spark/jars/
#COPY ./conf/* /opt/bitnami/spark/conf/

COPY src /helix.pipelines/src

RUN pipenv sync --system  # This should not be needed because the line below covers system also

RUN pipenv sync --dev --system

# COPY ./.git /helix.pipelines/.git
# COPY ./.pre-commit-config.yaml /helix.pipelines/.pre-commit-config.yaml
# COPY ./pyproject.toml /helix.pipelines/pyproject.toml
# COPY ./setup.cfg /helix.pipelines/setup.cfg

# COPY ./automapper /helix.pipelines/automapper
# COPY ./library /helix.pipelines/library
# COPY ./pydatabelt /helix.pipelines/pydatabelt
# COPY ./schemas /helix.pipelines/schemas
# COPY ./spf_tests /helix.pipelines/spf_tests
# COPY ./tests /helix.pipelines/tests
# COPY ./transformers /helix.pipelines/transformers
# COPY ./utilities /helix.pipelines/utilities


# run pre-commit once so it installs all the hooks and subsequent runs are fast
# RUN pre-commit install

# USER 1001
