
help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "clean-test - remove test and coverage artifacts"
	@echo "lint - check style"
	@echo "test - run tests quickly with the default Python"
	@echo "coverage - check code coverage quickly with the default Python"
	@echo "build - package"

all: default

default: clean dev_deps deps build

.venv:
	. $(VENV_NAME)/bin/activate
	#if [ ! -e ".venv/bin/activate_this.py" ] ; then virtualenv --clear .venv ; fi

VENV_NAME=venv
PYTHON_VERSION=3.6.11

.PHONY:venv
venv:
	~/.pyenv/versions/${PYTHON_VERSION}/bin/python3 -m venv $(VENV_NAME) && \
	. $(VENV_NAME)/bin/activate && \
	python -V

clean: clean-build clean-pyc clean-test

clean-build:
	rm -fr dist/

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

deps: .venv
	pip install -U -r requirements.txt -t ./src/libs

dev_deps: .venv
	pip install -U -r dev_requirements.txt

lint:
	pylint -r n src/main.py src/shared src/jobs tests

test:
	nosetests ./tests/* --config=.noserc

build: clean
	mkdir ./dist
	cp ./src/main.py ./dist
	cd ./src && zip -x main.py -x \*libs\* -r ../dist/jobs.zip .
	cd ./src/libs && zip -r ../../dist/libs.zip .


.PHONY:up
up:
	docker-compose -p boilerplate -f docker-compose.yml up --detach

.PHONY:down
down:
	docker-compose -p boilerplate -f docker-compose.yml down

run:
	cd dist && /usr/local/opt/spark/bin/spark-submit --master spark://localhost:7077 --py-files jobs.zip,libs.zip main.py --job wordcount

kubernetes:
	kubectl config use-context docker-desktop && \
	helm repo add bitnami https://charts.bitnami.com/bitnami && \
	helm install --set service.type=NodePort --set service.nodePort=7077 spark bitnami/spark
	helm install spark-dev bitnami/spark

# https://levelup.gitconnected.com/spark-on-kubernetes-3d822969f85b
kubernetes_run:
	export SUBMIT_PORT=$(kubectl get -o jsonpath="{.spec.ports[?(@.name=='cluster')].nodePort}" services spark-dev-master-svc --namespace spark-dev)
	export SUBMIT_PORT=$(kubectl get -o jsonpath="{.spec.ports[?(@.name=='cluster')].port}" services spark-dev-master-svc --namespace spark-dev)
	export SUBMIT_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}" --namespace spark-dev)
	export SUBMIT_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" services spark-dev-master-svc --namespace spark-dev)

	cd dist &&
	/usr/local/opt/spark/bin/spark-submit --master spark://$SUBMIT_IP:$SUBMIT_PORT \
		--conf spark.driver.bindAddress=0.0.0.0 \
		--conf spark.master.service.name=spark-dev-master-svc \
		--py-files jobs.zip,libs.zip main.py --job wordcount
		 && cd ..

		--conf spark.driver.port= \
		--conf spark.driver.host= \

	cd dist && /usr/local/opt/spark/bin/spark-submit --master spark://10.100.100.51:7077 \
		--py-files jobs.zip,libs.zip main.py --job wordcount && cd ..


	cd dist && /usr/local/opt/spark/bin/spark-submit --master k8s://https://kubernetes.docker.internal:6443 \
	--conf spark.kubernetes.container.image=imranq2/spark-py:3.0.1 \
	--conf spark.kubernetes.pyspark.pythonVersion=3 \
	--conf spark.kubernetes.container.image.pullPolicy=Always \
  	--py-files jobs.zip,libs.zip main.py --job wordcount
#	kubectl exec -ti --namespace default spark-release-worker-0 -- spark-submit --master spark://spark-release-master-svc:7077 \
#		--py-files jobs.zip,libs.zip main.py --job wordcount
#	cd dist && /usr/local/opt/spark/bin/spark-submit --master spark://kubernetes.docker.internal:6443 \
#	--py-files jobs.zip,libs.zip main.py --job wordcount

dashboard:
	# deploy kubernetes dashboard
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml
	kubectl proxy
	http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
	kubectl -n kube-system describe secret default

publish:
	cd /usr/local/opt/spark/
	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 ./usr/local/spark/kubernetes/dockerfiles/spark/Dockerfile build
	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 ./usr/local/spark/kubernetes/dockerfiles/spark/Dockerfile push

	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile build
	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile push

	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile -b java_image_tag=14-slim build
	bin/docker-image-tool.sh -r imranq2 -t 3.0.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile build

	docker push imranq2/spark-py:3.0.1
	docker push imranq2/spark:3.0.1


	docker build -t imranq2/boilerplate:1.0.0 .
	docker push imranq2/boilerplate:1.0.0
#
#export SUBMIT_PORT=$(kubectl get -o jsonpath="{.spec.ports[?(@.name=='cluster')].nodePort}" services spark-master-svc)
#export SUBMIT_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}")
#
#kubectl run --namespace default spark-client --rm --tty -i --restart='Never' \
#--image docker.io/bitnami/spark:3.0.1-debian-10-r65 \
#-- spark-submit --master spark://$SUBMIT_IP:$SUBMIT_PORT \
#--py-files jobs.zip,libs.zip main.py --job wordcount
#
#
#kubectl exec -it spark-master-0 -- spark-shell --master spark://$SUBMIT_IP:$SUBMIT_PORT
#
#
#kubectl run spark-client --rm --tty -i --restart='Never' \
#    --image docker.io/bitnami/spark:3.0.0 \
#    -- spark-shell --master spark://spark-release-master-svc:7077 --py-files jobs.zip,libs.zip main.py --job wordcount
#
#cd dist && /usr/local/opt/spark/bin/spark-submit --master spark://localhost:32391 \
#	--py-files jobs.zip,libs.zip main.py --job wordcount
#
#	helm delete spark
#	helm install --set service.type=NodePort spark bitnami/spark
#	helm install --set ingress.enabled=True spark bitnami/spark
#
kubectl describe pod wordcount
kubectl get event

kubectl describe pod -l spark-role=executor


./bin/docker-image-tool.sh -r <repo> -t my-tag -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build

cd /usr/local/opt/spark/
bin/docker-image-tool.sh -r imranq2 -t 3.0.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile -b java_image_tag=14-slim build

docker push imranq2/spark-py:3.0.1
docker push imranq2/spark:3.0.1
