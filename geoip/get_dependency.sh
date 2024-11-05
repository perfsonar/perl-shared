#!/bin/bash

if [ $# -ne 2 ]
  then
    echo "Illegal number of parameters"
    echo "Usage: $0 (PACKAGE|all) DEB/RPM"
    exit 1
fi

package=$1
version=$(echo $2 | tr [:lower:] [:upper:])

if [ "$version" != "DEB" ] && [ "$version" != "RPM" ]; then
    echo "Unknown OS version. Use DEB or RPM"
    exit 1
fi

my_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
package_list=${my_dir}"/packages.yml"

if [ "${package}" = "all" ]; then
    package=$(awk -F ':' '/^[^ ]+:/ {print $1}' ${package_list})
fi

for p in ${package}; do
    # Get url to download package
    if [ "$version" = "DEB" ]; then
        url=$(grep -A4 ^${p}: ${package_list} | awk '/deb_url:/ { print $2 }')
        filename=$(grep -A4 ^${p}: ${package_list} | awk '/deb_name:/ { print $2 }')
    elif [ "$version" = "RPM" ]; then
        url=$(grep -A4 ^${p}: ${package_list} | awk '/rpm_url:/ { print $2 }')
        filename=$(grep -A4 ^${p}: ${package_list} | awk '/rpm_name:/ { print $2 }')
    fi

    if [ ! -z $url ]; then
        curl -sS -o $filename -L $url;
        ls -lh $filename
    else
        echo "skipping $p";
    fi
done

