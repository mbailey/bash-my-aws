#!/bin/bash
#
# internal-functions
#
# Used by bash-my-aws functions to work with stdin and arguments.


skim-stdin() {

  # Append first token from each line of STDIN to argument list
  #
  # Implementation of `pipe-skimming` pattern.
  #
  #     $ stacks | skim-stdin foo bar
  #     foo bar huginn mastodon grafana
  #
  #     $ stacks
  #     huginn    CREATE_COMPLETE  2020-01-11T06:18:46.905Z  NEVER_UPDATED  NOT_NESTED
  #     mastodon  CREATE_COMPLETE  2020-01-11T06:19:31.958Z  NEVER_UPDATED  NOT_NESTED
  #     grafana   CREATE_COMPLETE  2020-01-11T06:19:47.001Z  NEVER_UPDATED  NOT_NESTED
  #
  # Typical usage within Bash-my-AWS functions:
  #
  #     local asg_names=$(skim-stdin "$@") # Append to arg list
  #     local asg_names=$(skim-stdin)      # Only draw from STDIN

  local skimmed_stdin="$([[ -t 0 ]] || awk 'ORS=" " { print $1 }')"

  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces

}

columnise() {
  if [[ $BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT == 'true' ]] && ! [[ -t 1 ]]; then
    cat
  else
    column -t -s $'\t'
  fi
}

__bma-using-aws-cli-v1() {
  aws --version | grep 'aws-cli/1' &>/dev/null
}


__bma_read_filters() {

  # Construct a string to be passed to `grep -E`
  #
  #     $ __bma_read_filters foo bar baz
  #     foo|bar|baz

  ( IFS=$'|'; printf -- "$*" )
}


__bma_error() {
  echo "ERROR: $@" > /dev/stderr
  return 1
}


__bma_usage() {
  echo "USAGE: ${FUNCNAME[1]} $@" > /dev/stderr
}


#
# The following two functions are deprecated
#


__bma_read_inputs() {
  # deprecated
  echo $(__bma_read_stdin) $@ |
    sed -E 's/\ +$//'         |
    sed -E 's/^\ +//'
}


__bma_read_stdin() {
  # deprecated - use skim-stdin
  [[ -t 0 ]] ||
    cat                  |
      awk '{ print $1 }' |
      tr '\n' ' '        |
      sed 's/\ $//'
}

