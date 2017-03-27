#!/bin/bash

SCRIPT_NAME='ab-whoami'

matches_debug() {
  if [ -z "$DEBUG" ]; then
    return 1
  fi
  if [[ $SCRIPT_NAME == "$DEBUG" ]]; then
    return 0
  fi
  return 1
}

debug() {
  local cyan='\033[0;36m'
  local no_color='\033[0;0m'
  local message="$@"
  matches_debug || return 0
  (>&2 echo -e "[${cyan}${SCRIPT_NAME}${no_color}]: $message")
}

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

assert_required_params() {
  local url="$1"

  if [ -n "$url" ]; then
    return 0
  fi

  usage

  if [ -z "$url" ]; then
    echo "Missing <url> argument"
  fi

  exit 1
}

usage(){
  local host n url
  echo "USAGE: ${SCRIPT_NAME} <url>"
  echo ''
  echo 'Description: Will hit up <url> N times'
  echo ''
  echo 'Arguments:'
  echo '  -h, --help       print this help text'
  echo '  -H, --host       host header to pass'
  echo '  -n               number of times to healthcheck, defaults to 1000'
  echo '  -v, --version    print the version'
  echo ''
  echo 'Environment:'
  echo '  DEBUG            print debug output'
  echo ''
}

version(){
  local directory
  directory="$(script_directory)"

  if [ -f "$directory/VERSION" ]; then
    cat "$directory/VERSION"
  else
    echo "unknown-version"
  fi
}

do_test(){
  local n="$1"
  local url="$2"
  local host="$3"
  local delay="$4"

  for i in $(seq 1 $n); do
    echo "$i" > /dev/null

    if [ -n "$host" ]; then
      curl --silent -I -H "Host: $host" "$url"
    else
      curl --silent -I "$url"
    fi

    sleep "$delay"
  done
}

main() {
  local delay host n url
  # Define args up here
  while [ "$1" != "" ]; do
    local param="$1"
    local value="$2"
    case "$param" in
      -d | --delay)
        delay="$value"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -H | --host)
        host="$value"
        shift
        ;;
      -n)
        n="$value"
        shift
        ;;
      -v | --version)
        version
        exit 0
        ;;
      # Arg with value
      # -x | --example)
      #   example="$value"
      #   shift
      #   ;;
      # Arg without value
      # -e | --example-flag)
      #   example_flag='true'
      #   ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        # Set main arguments
        if [ -z "$url" ]; then
          url="$param"
        # elif [ -z "$main_arg_2"]; then
        #   main_arg_2="$param"
        fi
        ;;
    esac
    shift
  done

  n=${n:-1000}
  delay=${delay:-0}

  assert_required_params "$url"

  do_test "$n" "$url" "$host" "$delay" \
  | grep --line-buffered 'HTTP/1' \
  | pv --line-mode --size "$n" --average-rate --rate --progress --bytes --timer --eta --force \
  | grep --line-buffered --invert-match '200'
}

main "$@"
