
#!/bin/bash

pkg=$1
[ -e brt-provides.txt ] && rm brt-provides.txt

printf "Getting list of base-runtime rpms... "
wget --quiet -O api.txt  https://github.com/fedora-modularity/base-runtime/blob/master/api.txt?raw=true && echo DONE || exit

printf "Modifying list of base-runtime rpms.."
# get package name of rpms on lines starting with '+', '*', or nothing
cat api.txt | sed '/^!/ d' | sed $'s/[+*]\t//g' | sed -e "s/-[^-]*-[^-]*$//" > brt-pkgs.txt && echo DONE || exit

printf "Getting capabilities provided by base-runtime packages... "
dnf repoquery --repofrompath brt,https://fedorapeople.org/groups/modularity/repos/base-runtime/26/ --provides -q `paste -s -d ' ' brt-pkgs.txt` > brt-provides.txt && echo DONE || exit

printf "Getting capabilities required by $1... "
dnf --repofrompath fedora.repo,/etc/yum.repos.d/fedora.repo repoquery --requires -q $pkg > tmp.txt && echo DONE || exit

while read cap; do
  if [[ $cap != *" = "* ]]; then
    grep -wq "^$cap*" brt-provides.txt || echo $cap >> ${pkg}-caps.txt
  else
    grep -wq "$cap" brt-provides.txt || echo $cap >> ${pkg}-caps.txt
  fi
done < tmp.txt

while read cap; do
  dnf repoquery --whatprovides $cap -q --latest-limit=1 >> cap2rpm.txt
done < ${pkg}-caps.txt

sort -u cap2rpm.txt | sed -e "s/-[^-]*-[^-]*$//" > ${pkg}-deps.txt

