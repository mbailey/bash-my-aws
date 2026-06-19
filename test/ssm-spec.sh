#!/usr/bin/env bash
source $(dirname $0)/bash-spec.sh
source $(dirname $0)/../lib/ssm-functions

# A multi-line script whose base64 encoding exceeds 76 columns, so BSD/macOS
# base64 wraps it -- the exact condition that broke ssm-send-command (BMA-8).
multiline_command=$'#!/usr/bin/env bash\necho "This is a multi-line script long enough to exceed seventy-six base64 columns"\nuptime'

describe "_bma_ssm_encode_command:" "$(
  context "encodes a multi-line command to a single line (no embedded newlines)" "$(
    blob=$(_bma_ssm_encode_command "$multiline_command")
    expect "$(printf '%s' "$blob" | wc -l | tr -d ' ')" to_be "0"
  )"

  context "produces a whitespace-free base64 blob" "$(
    blob=$(_bma_ssm_encode_command "$multiline_command")
    expect "$blob" to_match "^[A-Za-z0-9+/=]+$"
  )"

  context "round-trips a multi-line command through base64 --decode" "$(
    blob=$(_bma_ssm_encode_command "$multiline_command")
    expect "$(echo "$blob" | base64 --decode)" to_be "$multiline_command"
  )"

  context "round-trips a short single-line command (no regression)" "$(
    blob=$(_bma_ssm_encode_command "date +%F")
    expect "$(echo "$blob" | base64 --decode)" to_be "date +%F"
  )"
)"
