.PHONY: build condor-remote-configuration

RPMBUILD_DIRS := BUILD RPMS SOURCES SPECS SRPMS

NAME := condor-remote-configuration
SPEC := ${NAME}.spec
VERSION := $(shell grep -i version: "${SPEC}" | awk '{print $$2}')
SOURCE := ${NAME}-${VERSION}.tar.gz
DIR := ${NAME}-${VERSION}

build: condor-remote-configuration

condor-remote-configuration: SPECS/${SPEC} SOURCES/${SOURCE}
	mkdir -p BUILD RPMS SRPMS
	rpmbuild --define="_topdir ${PWD}" -ba SPECS/${SPEC}

SPECS/${SPEC}: ${SPEC}
	mkdir -p SPECS
	cp -f ${SPEC} SPECS

SOURCES/${SOURCE}:
	mkdir -p SOURCES
	rm -rf ${DIR}
	mkdir ${DIR}
	mkdir ${DIR}/config
	cp -f configure_condor_node ${DIR}
	cp -f condor_node ${DIR}
	cp -f LICENSE-2.0.txt ${DIR}
	cp -rf module ${DIR}
	cp -f config/* ${DIR}/config
	cp -f LICENSE-2.0.txt ${DIR}
	tar -cf ${SOURCE} ${DIR}
	mv "${SOURCE}" SOURCES

clean:
	rm -rf ${RPMBUILD_DIRS} ${DIR}
