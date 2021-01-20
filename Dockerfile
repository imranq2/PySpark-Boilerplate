FROM imranq2/spark-py:3.0.1
USER root

RUN pip3 install --upgrade --no-cache-dir pip && \
    pip3 install --no-cache-dir wheel && \
    pip3 install --no-cache-dir pipenv

COPY Pipfile* /helix.pipelines/

WORKDIR /helix.pipelines

#COPY ./jars/* /opt/bitnami/spark/jars/
#COPY ./conf/* /opt/bitnami/spark/conf/

COPY src /helix.pipelines/src

ENV PYTHONPATH=/helix.pipelines:/usr/local/lib/python3.7/dist-packages
ENV CLASSPATH=/helix.pipelines/jars:$CLASSPATH

ENV PYSPARK_MAJOR_PYTHON_VERSION=3

RUN pipenv sync --system  # This should not be needed because the line below covers system also

RUN pipenv sync --dev --system

USER 1001
