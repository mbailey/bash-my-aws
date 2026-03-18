# DO NOT MANUALLY MODIFY THIS FILE.
# Use 'scripts/build' to regenerate if required.

bma_path="${BMA_HOME:-$HOME/.bash-my-aws}"
_bma_asgs_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma asgs | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_aws-accounts_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma aws-accounts | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_buckets_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma buckets | awk '{ print $1 }')
  COMPREPLY=( $(compgen -W "${options}" -- ${word}) )
  return 0
}
_bma_certs_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma certs-arn | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_elbs_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma elbs | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_elbv2s_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma elbv2s | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_instances_completion() {
  local command="$1"
  local word="$2"
  local options="i-a i-b"

  if [[ $word != "--" ]] && [[ $word != "" ]]; then
    options=$(bma instances)
  fi

  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_keypairs_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma keypairs | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_regions_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma regions)
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_stacks_completion() {
  local command="$1"
  local word="$2"

  if [ "${COMP_CWORD}" -eq 1 ]; then
    COMPREPLY=($(compgen -W "$(bma stacks | awk '{ print $1 }')" -- "${word}"))
  elif [ "${COMP_CWORD}" -eq 2 ] && [ "${command}" = 'bma' ]; then
    COMPREPLY=($(compgen -W "$(bma stacks | awk '{ print $1 }')" -- "${word}"))
  else
    COMPREPLY=($(compgen -f "${word}"))
  fi
  return 0
}
_bma_target-groups_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma target-groups | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_vpcs_completion() {
  local command="$1"
  local word="$2"
  local options=$(bma vpcs | awk '{ print $1 }')
  COMPREPLY=($(compgen -W "${options}" -- ${word}))
  return 0
}
_bma_completion() {
  local word
  word="$2"

  if [ "${COMP_CWORD}" -eq 1 ]; then
    _bma_functions_completion "$word"
  elif [ "${COMP_CWORD}" -eq 2 ] && [ "$3" = "type" ]; then
    _bma_functions_completion "$word"
  else
    _bma_subcommands_completion "${COMP_WORDS[1]}" "$word"
  fi
}

_bma_functions_completion() {
  local word all_funcs
  word="$1"
  all_funcs=$(echo "type" && cat "${bma_path}/functions" | command grep -v "^#")
  COMPREPLY=($(compgen -W "${all_funcs}" -- ${word}))
  return
}

_bma_subcommands_completion() {
  local subcommand word subcommand_completion
  subcommand="$1"
  word="$2"

  subcommand_completion=$(
    complete -p                       |
    command grep "_bma_"              |
    command grep "\s${subcommand:-}$" |
    command awk '{print $3}'
  )

  if [ -n "${subcommand_completion}" ]; then
    $subcommand_completion "bma" "${word:-}"
  fi
  return 0
}
_cachews_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD -eq 1 ]]; then
        local services=$(ls ${CACHEWS_DIR}/${AWS_PROFILE/-admin}/${AWS_DEFAULT_REGION}/ | sed 's/\/.*//')
        COMPREPLY=( $(compgen -W "$services" -- $cur) )
        return 0
    elif [[ $COMP_CWORD -eq 2 ]]; then
        local api_calls=$(ls ${CACHEWS_DIR}/${AWS_PROFILE/-admin}/${AWS_DEFAULT_REGION}/$prev | sed 's/\.json//')
        COMPREPLY=( $(compgen -W "$api_calls" -- $cur) )
        return 0
    elif [[ $COMP_CWORD -ge 3 && $prev == '--output' ]]; then
        COMPREPLY=( $(compgen -W "json text table" -- $cur) )
        return 0
    elif [[ $COMP_CWORD -ge 3 && $prev != '--query' ]]; then
        COMPREPLY=( $(compgen -W "--output --query" -- $cur) )
        return 0
    fi
}

complete -F _cachews_completion cachews
complete -F _bma_asgs_completion asg-capacity
complete -F _bma_asgs_completion asg-detach-instances
complete -F _bma_asgs_completion asg-instances
complete -F _bma_asgs_completion asg-launch-configuration
complete -F _bma_asgs_completion asg-processes_suspended
complete -F _bma_asgs_completion asg-resume
complete -F _bma_asgs_completion asg-scaling-activities
complete -F _bma_asgs_completion asg-stack
complete -F _bma_asgs_completion asg-suspend
complete -F _bma_asgs_completion asgs
complete -F _bma_aws-accounts_completion aws-account-cost-explorer
complete -F _bma_aws-accounts_completion aws-account-cost-recommendations
complete -F _bma_aws-accounts_completion aws-accounts
complete -F _bma_buckets_completion bucket-acls
complete -F _bma_buckets_completion bucket-remove
complete -F _bma_buckets_completion bucket-remove-force
complete -F _bma_buckets_completion bucket-size
complete -F _bma_buckets_completion buckets
complete -F _bma_certs_completion cert-chain
complete -F _bma_certs_completion cert-delete
complete -F _bma_certs_completion cert-ificate
complete -F _bma_certs_completion cert-resource-record-valid
complete -F _bma_certs_completion cert-users
complete -F _bma_certs_completion cert-verify
complete -F _bma_certs_completion certs
complete -F _bma_certs_completion certs-arn
complete -F _bma_elbs_completion elb-azs
complete -F _bma_elbs_completion elb-dnsname
complete -F _bma_elbs_completion elb-instances
complete -F _bma_elbs_completion elb-stack
complete -F _bma_elbs_completion elb-subnets
complete -F _bma_elbs_completion elb-tag
complete -F _bma_elbs_completion elb-tags
complete -F _bma_elbs_completion elbs
complete -F _bma_elbv2s_completion elbv2-azs
complete -F _bma_elbv2s_completion elbv2-dnsname
complete -F _bma_elbv2s_completion elbv2-subnets
complete -F _bma_elbv2s_completion elbv2-target-groups
complete -F _bma_elbv2s_completion elbv2s
complete -F _bma_instances_completion instance-asg
complete -F _bma_instances_completion instance-az
complete -F _bma_instances_completion instance-console
complete -F _bma_instances_completion instance-dns
complete -F _bma_instances_completion instance-health-set-unhealthy
complete -F _bma_instances_completion instance-iam-profile
complete -F _bma_instances_completion instance-ip
complete -F _bma_instances_completion instance-profile
complete -F _bma_instances_completion instance-profile-role
complete -F _bma_instances_completion instance-rdp
complete -F _bma_instances_completion instance-ssh
complete -F _bma_instances_completion instance-ssh-details
complete -F _bma_instances_completion instance-ssm
complete -F _bma_instances_completion instance-ssm-platform-type
complete -F _bma_instances_completion instance-ssm-port-forward
complete -F _bma_instances_completion instance-stack
complete -F _bma_instances_completion instance-start
complete -F _bma_instances_completion instance-state
complete -F _bma_instances_completion instance-stop
complete -F _bma_instances_completion instance-stop-protection
complete -F _bma_instances_completion instance-stop-protection-disable
complete -F _bma_instances_completion instance-stop-protection-enable
complete -F _bma_instances_completion instance-subnet
complete -F _bma_instances_completion instance-tag
complete -F _bma_instances_completion instance-tag-create
complete -F _bma_instances_completion instance-tag-delete
complete -F _bma_instances_completion instance-tags
complete -F _bma_instances_completion instance-tags-v2
complete -F _bma_instances_completion instance-terminate
complete -F _bma_instances_completion instance-termination-protection
complete -F _bma_instances_completion instance-termination-protection-disable
complete -F _bma_instances_completion instance-termination-protection-enable
complete -F _bma_instances_completion instance-type
complete -F _bma_instances_completion instance-userdata
complete -F _bma_instances_completion instance-volumes
complete -F _bma_instances_completion instance-vpc
complete -F _bma_instances_completion instances
complete -F _bma_keypairs_completion keypair-delete
complete -F _bma_keypairs_completion keypairs
complete -F _bma_regions_completion region
complete -F _bma_stacks_completion stack-arn
complete -F _bma_stacks_completion stack-asg-instances
complete -F _bma_stacks_completion stack-asgs
complete -F _bma_stacks_completion stack-cancel-update
complete -F _bma_stacks_completion stack-delete
complete -F _bma_stacks_completion stack-diff
complete -F _bma_stacks_completion stack-drift-detect
complete -F _bma_stacks_completion stack-drift-resources
complete -F _bma_stacks_completion stack-drift-status
complete -F _bma_stacks_completion stack-elbs
complete -F _bma_stacks_completion stack-events
complete -F _bma_stacks_completion stack-exports
complete -F _bma_stacks_completion stack-failure
complete -F _bma_stacks_completion stack-instances
complete -F _bma_stacks_completion stack-outputs
complete -F _bma_stacks_completion stack-parameters
complete -F _bma_stacks_completion stack-recreate
complete -F _bma_stacks_completion stack-resources
complete -F _bma_stacks_completion stack-status
complete -F _bma_stacks_completion stack-tail
complete -F _bma_stacks_completion stack-template
complete -F _bma_stacks_completion stack-template-changeset-latest
complete -F _bma_stacks_completion stack-update
complete -F _bma_stacks_completion stacks
complete -F _bma_target-groups_completion target-group-targets
complete -F _bma_target-groups_completion target-groups
complete -F _bma_vpcs_completion vpc-az-count
complete -F _bma_vpcs_completion vpc-azs
complete -F _bma_vpcs_completion vpc-endpoint-policy
complete -F _bma_vpcs_completion vpc-endpoints
complete -F _bma_vpcs_completion vpc-igw
complete -F _bma_vpcs_completion vpc-lambda-functions
complete -F _bma_vpcs_completion vpc-nat-gateways
complete -F _bma_vpcs_completion vpc-network-acls
complete -F _bma_vpcs_completion vpc-rds
complete -F _bma_vpcs_completion vpc-route-tables
complete -F _bma_vpcs_completion vpc-subnets
complete -F _bma_vpcs_completion vpcs
complete -f stack-validate
complete -F _bma_completion bma
