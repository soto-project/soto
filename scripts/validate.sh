#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftNIO open source project
##
## Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftNIO project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

SWIFT_FORMAT_VERSION=0.51.15

set -eu
here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function check_all_services_in_package() {
    for folder in $here/../Sources/Soto/Services/*; do
        service=$(basename $folder)
        if [ -z "$(grep "name: \"Soto$service\"" $here/../Package.swift)" ]; then
            printf "\033[0;31m$service is not in Package.swift\033[0m\n"
            exit -1
        fi
    done
}

function replace_acceptable_years() {
    # this needs to replace all acceptable forms with 'YEARS'
    sed -e 's/20[12][0123456789]-20[12][0123456789]/YEARS/' -e 's/20[12][0123456789]/YEARS/' -e '/^#!/ d'
}

printf "=> Checking services in Package.swift... "
check_all_services_in_package
printf "\033[0;32mokay.\033[0m\n"

printf "=> Checking format... "
FIRST_OUT="$(git status --porcelain)"
git ls-files '*.swift' | grep -v "Sources/Soto/Services" | xargs swift format format --parallel --in-place
git diff --exit-code '*.swift'

SECOND_OUT="$(git status --porcelain)"
if [[ "$FIRST_OUT" != "$SECOND_OUT" ]]; then
  printf "\033[0;31mformatting issues!\033[0m\n"
  git --no-pager diff
  exit 1
else
  printf "\033[0;32mokay.\033[0m\n"
fi

printf "=> Checking license headers... "
tmp=$(mktemp /tmp/.soto-core-sanity_XXXXXX)

for language in swift-or-c; do
  declare -a matching_files
  declare -a exceptions
  expections=( )
  matching_files=( -name '*' )
  case "$language" in
      swift-or-c)
        exceptions=( -name 'Package.swift' -o -path '*templates/*' -o -path '*scripts/*')
        matching_files=( -name '*.swift' -o -name '*.c' -o -name '*.h' )
        cat > "$tmp" <<"EOF"
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) YEARS the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
EOF
        ;;
      bash)
        matching_files=( -name '*.sh' )
        cat > "$tmp" <<"EOF"
##===----------------------------------------------------------------------===##
##
## This source file is part of the Soto for AWS open source project
##
## Copyright (c) YEARS the Soto project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of Soto project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##
EOF
      ;;
    *)
      echo >&2 "ERROR: unknown language '$language'"
      ;;
  esac

  lines_to_compare=$(cat "$tmp" | wc -l | tr -d " ")
  # need to read one more line as we remove the '#!' line
  lines_to_read=$(expr "$lines_to_compare" + 1)
  expected_sha=$(cat "$tmp" | shasum)

  (
    cd "$here/.."
    find . \
      \( \! -path '*/.build/*' -a \
      \( "${matching_files[@]}" \) -a \
      \( \! \( "${exceptions[@]}" \) \) \) | while read line; do
      if [[ "$(head -n $lines_to_read "$line" | replace_acceptable_years | head -n $lines_to_compare | shasum)" != "$expected_sha" ]]; then
        printf "\033[0;31mmissing headers in file '$line'!\033[0m\n"
        diff -u <(cat "$line" | head -n $lines_to_read | replace_acceptable_years | head -n $lines_to_compare) "$tmp"
        exit 1
      fi
    done
    printf "\033[0;32mokay.\033[0m\n"
  )
done

rm "$tmp"
