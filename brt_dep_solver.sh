#!/bin/bash

#set -e
pkg=${1}

CLEAN=${CLEAN:-true}
VERBOSE=${VERBOSE:-false}

function verbose_echo {
    [ "$VERBOSE" != "true" ] && return

    echo "$@"
}

# TODO: add other known dependency modules
function get-baseruntime-caps {

    provided_caps=brt-provides.txt
    verbose_echo -n "Getting list of base-runtime rpms... "
    wget --quiet -O api.txt  https://github.com/fedora-modularity/base-runtime/blob/master/api.txt?raw=true && verbose_echo "DONE"

    verbose_echo -n "Modifying list of base-runtime rpms.."
    # get package name of rpms on lines starting with '+', '*', or nothing
    cat api.txt | sed '/^!/ d' | sed $'s/[+*]\t//g' | sed -e "s/-[^-]*-[^-]*$//" > brt-pkgs.txt && verbose_echo "DONE"

    verbose_echo -n "Getting capabilities provided by base-runtime packages... "
    dnf repoquery --repofrompath brt,https://fedorapeople.org/groups/modularity/repos/base-runtime/26/ --provides -q `paste -s -d ' ' brt-pkgs.txt` > ${provided_caps} && verbose_echo "DONE"

}

function resolve-deps {
    if [[ ${1} == "runtime" ]]; then
      runtime=true
    elif [[ ${1} == "build" ]]; then
      runtime=false
    else
      echo "resolve-deps: Invalid operation ${1}"
      exit -1
    fi

    if [ "${runtime}" = "true" ]; then
      DIR=${pkg}-runtime-res-files
    else
      DIR=${pkg}-build-res-files
    fi

    mkdir ${DIR}
    cd ${DIR}

    get-baseruntime-caps

    verbose_echo -n "Getting ${1} capabilities required by ${pkg}... "
    # TODO: use remote path for fedora repository
    SRPM_FLAG=
    [ "${runtime}" = "true" ] || SRPM_FLAG=--srpm
      dnf --repofrompath fedora.repo,/etc/yum.repos.d/fedora.repo repoquery $SRPM_FLAG --requires -q ${pkg} > ${pkg}-caps.txt && verbose_echo "DONE"
    while read cap; do
      if [[ $cap != *" = "* ]]; then
        grep -wq "^${cap}*" ${provided_caps} || echo ${cap} >> ${pkg}-filtered-caps.txt
      else
        grep -wq "${cap}" ${provided_caps} || echo ${cap} >> ${pkg}-filtered-caps.txt
      fi
    done < ${pkg}-caps.txt

    while read cap; do
      dnf repoquery --whatprovides ${cap} -q --latest-limit=1 >> cap2rpm.txt
    done < ${pkg}-filtered-caps.txt

    if [ "$runtime" = "true" ]; then
      sort -u cap2rpm.txt | sed -e "s/-[^-]*-[^-]*$//" > ../${pkg}-runtime-deps.txt
    else
      sort -u cap2rpm.txt | sed -e "s/-[^-]*-[^-]*$//" > ../${pkg}-build-deps.txt
    fi

    cd ..
    ${CLEAN} && rm ${DIR}/* && rmdir ${DIR}
}

resolve-deps "build"
resolve-deps "runtime"
