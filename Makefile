
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
	cd dist && /usr/local/opt/spark/bin/spark-submit --py-files jobs.zip,libs.zip main.py --job wordcount