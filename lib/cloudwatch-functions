#!/bin/bash
#
# cloudwatch-functions

cloudwatch-alarms(){

  # List Cloudwatch Alarms
  #
  #    USAGE: cloudwatch-alarms [filter]
  #
  #    $ things
  #    thing-1234567890123  Online  Amazon Linux                              2           192.168.1.10    server001.example.com
  #    thing-1234567890124  Offline Amazon Linux                              2           192.168.1.10    server001.example.com
  #    thing-1234567890125  Online  Amazon Linux                              2           192.168.1.10    server001.example.com
  #
  #    *Optionally provide a filter string for a `| grep` effect with tighter columisation:*
  #
  #    $ things Online
  #    i-1234567890123 Online  Microsoft Windows Server 2019 Datacenter  68.0.11111  192.168.1.10    server001.example.com
  #    i-1234567890124 Online  Microsoft Windows Server 2022 Datacenter  68.0.11112  192.168.1.20    winserver002.example.com

  local alarms=$(skim-stdin)
  local filters=$(__bma_read_filters $@)

  local arg_filters="${alarms:+--alarm-names "${alarms}"}"

  aws cloudwatch describe-alarms \
    $arg_filters \
    --output text \
    --query "
      MetricAlarms[].[
        AlarmName,
        StateValue,
        ActionsEnabled,
        join(',', AlarmActions || \`[]\`)
      ]" \
  | grep -E -- "$filters" \
  | LC_ALL=C sort -t $'\t' -k 1 \
  | columnise
}

cloudwatch-alarm-delete() {
  local alarms="$(skim-stdin "$@")"
  [[ -z $alarms ]] && __bma_usage "alarm_name [alarm_name]" && return 1

  alarm_names_json=$(printf "%s\n" "$alarms" | jq -R '.' | jq -crs '{"AlarmNames":.}')

  echo "You are about to delete the following Cloudwatch Alarms:"
  echo "$alarm_names_json" | jq .
  [ -t 0 ] || exec </dev/tty # reattach keyboard to STDIN
  local regex_yes="^[Yy]$"
  read -p "Are you sure you want to continue? " -n 1 -r
  echo
  if [[ $REPLY =~ $regex_yes ]]; then
    aws cloudwatch delete-alarms --cli-input-json "${alarm_names_json}"
  fi
}

cloudwatch-alarm-actions-disable() {
  local alarms="$(skim-stdin "$@")"
  [[ -z $alarms ]] && __bma_usage "alarm_name [alarm_name]" && return 1
  
  alarm_names_json=$(printf "%s\n" "$alarms" | jq -R '.' | jq -crs '{"AlarmNames":.}')

  echo "You are about to disable alarm actions on the following Cloudwatch Alarms:"
  echo "$alarm_names_json" | jq .
  [ -t 0 ] || exec </dev/tty # reattach keyboard to STDIN
  local regex_yes="^[Yy]$"
  read -p "Are you sure you want to continue? " -n 1 -r
  echo
  if [[ $REPLY =~ $regex_yes ]]; then
    aws cloudwatch disable-alarm-actions --cli-input-json "${alarm_names_json}"
  fi
}

cloudwatch-alarm-actions-enable() {
  local alarms="$(skim-stdin "$@")"
  [[ -z $alarms ]] && __bma_usage "alarm_name [alarm_name]" && return 1

  alarm_names_json=$(printf "%s\n" "$alarms" | jq -R '.' | jq -crs '{"AlarmNames":.}')

  echo "You are about to enable alarm actions on the following Cloudwatch Alarms:"
  echo "$alarm_names_json" | jq .
  [ -t 0 ] || exec </dev/tty # reattach keyboard to STDIN
  local regex_yes="^[Yy]$"
  read -p "Are you sure you want to continue? " -n 1 -r
  echo
  if [[ $REPLY =~ $regex_yes ]]; then
    aws cloudwatch enable-alarm-actions --cli-input-json "${alarm_names_json}"
  fi
}
