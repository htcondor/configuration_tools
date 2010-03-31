.PHONY: build condor-wallaby

RPMBUILD_DIRS := BUILD BUILDROOT RPMS SOURCES SPECS SRPMS

NAME := condor-wallaby
SPEC := ${NAME}.spec
VERSION := $(shell grep -i version: "${SPEC}" | awk '{print $$2}')
RELEASE := $(shell grep -i 'define rel' "${SPEC}" | awk '{print $$3}')
SOURCE := ${NAME}-${VERSION}-${RELEASE}.tar.gz
DIR := ${NAME}-${VERSION}

build: condor-wallaby

condor-wallaby: SPECS/${SPEC} SOURCES/${SOURCE}
	mkdir -p BUILD RPMS SRPMS
	rpmbuild --define="_topdir ${PWD}" -ba SPECS/${SPEC}

SPECS/${SPEC}: ${SPEC}
	mkdir -p SPECS
	cp -f ${SPEC} SPECS

SOURCES/${SOURCE}:
	mkdir -p SOURCES
	rm -rf ${DIR}
	mkdir ${DIR}
	cp -f condor_configure_pool ${DIR}
	cp -f condor_configure_store ${DIR}
	cp -f condor_configd ${DIR}
	cp -f utils.py ${DIR}
	cp -f config/* ${DIR}
	cp -f LICENSE-2.0.txt README ${DIR}
	tar -cf ${SOURCE} ${DIR}
	mv "${SOURCE}" SOURCES

clean:
	rm -rf ${RPMBUILD_DIRS} ${DIR}
