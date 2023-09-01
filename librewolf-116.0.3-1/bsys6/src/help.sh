#!/usr/bin/env bash

source $BSYS6/exports/target.sh

cat <<EOF
bsys6 - The 6th generation LibreWolf Build System

Usage: bsys6 [command]

Commands:                                                                   | Artifacts:
EOF

command_descr() {
  case "$1" in
  bootstrap) echo "Bootstrap the build system with mach" ;;
  build_docker) echo "Run the 'build' command inside Docker" ;;
  build_image) echo "Build the docker image used by 'build_docker'" ;;
  build) echo "Build LibreWolf (requires a prepared system)" ;;
  clean) echo "Remove the work directory (including source)" ;;
  clobber) echo "Clean the current source directory" ;;
  help) echo "Show this page" ;;
  msix) echo "Build a MSIX package for Windows" ;;
  nupkg) echo "Build a .nupkg to be used for Chocolatey" ;;
  package) echo "Package LibreWolf into a zip/tarball" ;;
  package_docker) echo "Run the 'package' command inside Docker" ;;
  prepare) echo "Prepare the build enviroment and install dependencies" ;;
  release) printf "Publish all the various artifacts\n(Should only be used in CI)" ;;
  run) echo "Start the built browser" ;;
  setup) echo "Build the installer for Windows with nsis" ;;
  source) printf "Download the latest LibreWolf source code into\nthe working directory" ;;
  update) echo "Update the version cache" ;;
  portable) printf "Build a zip containing a portable LibreWolf using\nhttps://codeberg.org/ltguillaume/librewolf-portable" ;;
  deb) printf "Build the Debian .deb pacakge file";;
  rpm) printf "Create a Redhat/Fedora-style .rpm package file";;
  *) ;;
  esac
}

for file in $BSYS6/*.sh; do
  basename="${file##*/}"
  command="${basename%.sh}"
  descr="$(command_descr $command)"
  if [ "$descr" == "" ]; then
    if [[ "${AVAILABLE_ARTIFACTS,,}" =~ (^|[[:space:]])"$command"($|[[:space:]]) ]]; then
      printf "  %-73s | %s\n" "$command" "${command^^}"
    else
      echo "  $command"
    fi
  else
    ogIFS="$IFS"
    IFS=$'\n'
    for line in $descr; do
      if [ "$command" == "" ]; then
        printf "%-19s %s\n" "" "$line"
      else
        if [[ "${AVAILABLE_ARTIFACTS,,}" =~ (^|[[:space:]])"$command"($|[[:space:]]) ]]; then
          printf "  %-15s - %-55s | %s\n" "$command" "$line" "${command^^}"
        else
          printf "  %-15s - %s\n" "$command" "$line"
        fi
      fi
      command=""
    done
    IFS="$ogIFS"
  fi
done

cat <<EOF

Commands may be customized by setting the following environment variables:
  TARGET  - The target platform (available: $AVAILABLE_TARGETS; currently: $TARGET)
  ARCH    - The target architecture (available: $AVAILABLE_ARCHS; currently: $ARCH)
  VERSION - The version of LibreWolf to build (default: latest)
  WORKDIR - The directory to use for temporary files (currently: $WORKDIR)

  You can also persist these settings by creating a file named "env.sh" in the
  same directory as this script, and setting the variables there, for example:

  '''
  export WORKDIR=/mnt/ssd2/bsys6-work
  '''
EOF
