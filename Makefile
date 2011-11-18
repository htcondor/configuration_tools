.PHONY: build condor-wallaby

RPMBUILD_DIRS := BUILD BUILDROOT RPMS SOURCES SPECS SRPMS

NAME := condor-wallaby
SPEC := ${NAME}.spec
VERSION := $(shell grep -i Version: "${SPEC}" | awk '{print $$2}')
SOURCE := ${NAME}-${VERSION}.tar.gz
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
	mkdir ${DIR}/doc
	cp -f condor_configure_pool ${DIR}
	cp -f condor_configure_store ${DIR}
	cp -f condor_configd ${DIR}
	cp -Rf module ${DIR}
	cp -f config/* ${DIR}
	cp -f LICENSE-2.0.txt README ${DIR}
	cp -f doc/* ${DIR}/doc
	tar -cf ${SOURCE} ${DIR}
	mv "${SOURCE}" SOURCES

clean:
	rm -rf ${RPMBUILD_DIRS} ${DIR}
