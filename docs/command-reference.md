title: Bash-my-AWS Command Reference
description: Command reference for Bash-my-AWS - CLI Tools for AWS.
    Bash-my-AWS provides short memorable commands for managing resources
    in Amazon Web Services.

Bash-my-AWS provides over 120 commands for managing AWS Resources but fear not!

Effort has been put into making them *discoverable*, *memorable* and hopefully in most
cases *obvious*.

The reference material below is all extracted from the source of the commands.

Lists in this project are alphabetised except where it makes sense not to.
The first few sets of commands were chosen because they are likely to be of
the most interest to readers.

!!! Note "General Rules"
    - Commands expect `$AWS_DEFAULT_REGION` environment variable to be set
      (check/set with `region` command)
    - Most commands that list resources (`stacks`, `instances , etc)
      accept filter term as first arg.
        - *e.g. `stacks blah` is equivalent to `stacks | grep blah`*
    - Most commands accept resource identifiers via STDIN
      (first token of each line)
    - Resources are generally listed in chronological order of creation.




## aws-account-commands


### aws-accounts

List AWS Accounts in an [Organization](https://aws.amazon.com/organizations/)

   $ aws-accounts
   089834043791  account1 ACTIVE  INVITED  1488257653.638  mike-aws@bailey.net.au
   812094344564  account2 ACTIVE  CREATED  1537922950.972  mike-bash-my-aws@bailey.net.au
   001721147249  account3 ACTIVE  INVITED  1548752330.723  mike@bailey.net.au
   867077406134  account4 ACTIVE  CREATED  1557910982.885  mike-deleteme@bailey.net.au
   892345420873  account5 ACTIVE  CREATED  1557911243.358  mike-delete@bailey.net.au

*Optionally provide a filter string for a `| grep` effect with tighter columisation:*


### aws-account-alias

Retrieve AWS Account Alias for current account

    $ aws-account-alias
    example-account-prod


### aws-account-id

Retrieve AWS Account ID for current account

    $ aws-account-id
    012345678901


### aws-account-each

Run a script/command across a number of AWS Accounts

    USAGE: aws-account-each cmd # pipe in AWS_ACCOUNT_IDS

    $ grep non_prod AWS_ACCOUNTS | aws-account-each stacks FAILED

    # account=012345678901 alias=example-account-prod
    example-stack1-prod  CREATED_FAILED
    example-stack2-prod  UPDATE_ROLLBACK_FAILED
    # account=123456789012 alias=example-account-staging
    example-stack1-staging  CREATED_FAILED
    example-stack2-staging  UPDATE_ROLLBACK_FAILED

!!! Note
    In order to use `aws-account-each`, you need to be authenticated with an
    IAM Role that can assume a Role in each of the specified accounts.
    Check the source for more info.


### aws-panopticon

aws-panopticon was previous name for aws-account-each()


### aws-account-cost-explorer

Use with an AWS Organisations Master Account to open multiple accounts
in Cost Explorer.

    $ grep demo AWS_ACCOUNTS | aws-account-cost-explorer
    #=> Opens web browser to AWS Cost Explorer with accounts selected


### aws-account-cost-recommendations

Use with an AWS Organisations Master Account to open multiple accounts
in Cost Recommendations.

    $ grep non_prod AWS_ACCOUNTS | aws-account-each stacks FAILED
    #=> Opens web browser to AWS Cost Recommendations with accounts selected


## region-commands


### regions

List regions

The region() function must be sourced in order to update the
AWS_DEFAULT_REGION environment variable. This is because it
cannot update an environment variable when run as a subprocess.

    $ regions
    ap-northeast-1
    ap-northeast-2
    ap-south-1
    ap-southeast-1
    ap-southeast-2
    ...
    us-west-2


### region

Get/Set `$AWS_DEFAULT_REGION` shell environment variable

    $ region
    us-east-1

    $ region ap-southeast-2

    $ region
    ap-southeast-2


### region-each

Run a command in every region.
Any output lines will be appended with "#${REGION}".

    $ region-each stacks
    example-ec2-ap-northeast-1  CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED  #ap-northeast-1
    example-ec2-ap-northeast-2  CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED  #ap-northeast-2
    ...
    example-ec2-us-west-2       CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED  #us-west-2


## stack-commands


### stacks

List CloudFormation stacks.

To make it fly we omit stacks with status of DELETE_COMPLETE
Output is sorted by CreationTime

    $ stacks
    nagios          CREATE_COMPLETE  2018-03-12T11:41:31Z  NEVER_UPDATED  NOT_NESTED
    postgres1       CREATE_COMPLETE  2019-04-14T15:22:44Z  NEVER_UPDATED  NOT_NESTED
    postgres2       CREATE_COMPLETE  2019-05-18T05:45:50Z  NEVER_UPDATED  NOT_NESTED
    prometheus-web  CREATE_COMPLETE  2019-11-23T15:57:04Z  NEVER_UPDATED  NOT_NESTED

*Provide a filter string for a `| grep` effect with tighter columisation:*

    $ stacks postgres
    postgres1  CREATE_COMPLETE  2019-04-14T15:22:44Z  NEVER_UPDATED  NOT_NESTED
    postgres2  CREATE_COMPLETE  2019-05-18T05:45:50Z  NEVER_UPDATED  NOT_NESTED


### stack-arn

Returns ARN(s) for stacks.

    USAGE: stack-arn stack [stack]

    $ stack-arn prometheus-web
    arn:aws:cloudformation:us-east-1:000000000000:stack/prometheus-web/805e081c-b8eb-4f6c-9872-2b5cddc77fba

*Supports multiple stack names from STDIN*:

    $ stacks | stack-arn
    arn:aws:cloudformation:us-east-1:000000000000:stack/nagios/c0f0ef04-b505-4c0c-87cd-ca924153ad1c
    arn:aws:cloudformation:us-east-1:000000000000:stack/postgres1/758b0ba2-60f2-4432-8935-f79f47708f23
    arn:aws:cloudformation:us-east-1:000000000000:stack/postgres2/7420bbd4-3026-444f-b55b-fa0a9d564730
    arn:aws:cloudformation:us-east-1:000000000000:stack/prometheus-web/805e081c-b8eb-4f6c-9872-2b5cddc77fba


### stack-cancel-update

Cancel an in-progress stack update


### stack-create

Create a CloudFormation Stack

*See suggested [CloudFormation File Naming Conventions](/cloudformation-naming/)
to take advantage of shorter commands*

    USAGE: stack-create stack [template-file] [parameters-file]             \
                [--capabilities=OPTIONAL_VALUE] [--role-arn=OPTIONAL_VALUE]

    $ stack-create params/asg-params-prod.json
    Resolved arguments: asg-prod ./asg.yml params/asg-params-prod.json
    arn:aws:cloudformation:ap-southeast-2:812094344564:stack/asg-prod/98d40130-23f2-11ea-b7c1-06494f833672
    ----------------------------------------------------------------------------------------------
    |                                     DescribeStackEvents                                    |
    +---------------------------+-----------+------------------------------+---------------------+
    |  2019-12-21T13:05:44.261Z |  asg-prod |  AWS::CloudFormation::Stack  |  CREATE_IN_PROGRESS |
    --------------------------------------------------------------------------------------------------------------------
    |                                                DescribeStackEvents                                               |
    +--------------------------+----------------------+-----------------------------------------+----------------------+
    |  2019-12-21T13:05:44.261Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:48.351Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:48.828Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:49.187Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_COMPLETE     |
    |  2019-12-21T13:05:51.230Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:51.837Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:52.950Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_COMPLETE     |
    |  2019-12-21T13:05:54.493Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_COMPLETE     |
    +--------------------------+----------------------+-----------------------------------------+----------------------+


### stack-update

Update a CloudFormation Stack

*See suggested [CloudFormation File Naming Conventions](/cloudformation-naming/)
to take advantage of shorter commands*

    USAGE: stack-update stack [template-file] [parameters-file] \
                  [--capabilities=OPTIONAL_VALUE] [--role-arn=OPTIONAL_VALUE]

    $ stack-update params/asg-params-prod.json
    Resolved arguments: asg-prod ./asg.yml params/asg-params-prod.json
    arn:aws:cloudformation:ap-southeast-2:812094344564:stack/asg-prod/98d40130-23f2-11ea-b7c1-06494f833672
    --------------------------------------------------------------------------------------------------------------------
    |                                                DescribeStackEvents                                               |
    +--------------------------+----------------------+-----------------------------------------+----------------------+
    |  2019-12-21T13:05:44.261Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:48.351Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:48.828Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:49.187Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_COMPLETE     |
    |  2019-12-21T13:05:51.230Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:51.837Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS  |
    |  2019-12-21T13:05:52.950Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_COMPLETE     |
    |  2019-12-21T13:05:54.493Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_COMPLETE     |
    |  2019-12-21T13:12:43.731Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_IN_PROGRESS  |
    |  2019-12-21T13:12:48.294Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  UPDATE_IN_PROGRESS  |
    -------------------------------------------------------------------------------------------------------------------------------------
    |                                                        DescribeStackEvents                                                        |
    +--------------------------+----------------------+-----------------------------------------+---------------------------------------+
    |  2019-12-21T13:05:44.261Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:48.351Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:48.828Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:49.187Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_COMPLETE                      |
    |  2019-12-21T13:05:51.230Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:51.837Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:52.950Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_COMPLETE                      |
    |  2019-12-21T13:05:54.493Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_COMPLETE                      |
    |  2019-12-21T13:12:43.731Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_IN_PROGRESS                   |
    |  2019-12-21T13:12:48.294Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  UPDATE_IN_PROGRESS                   |
    |  2019-12-21T13:14:05.182Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  UPDATE_COMPLETE                      |
    |  2019-12-21T13:14:07.118Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_COMPLETE_CLEANUP_IN_PROGRESS  |
    |  2019-12-21T13:14:07.820Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_COMPLETE                      |
    +--------------------------+----------------------+-----------------------------------------+---------------------------------------+


### stack-delete

Delete a CloudFormation Stack

    USAGE: stack-delete stack [stack]

    $ stacks | stack-delete
    You are about to delete the following stacks:
    asg-prod
    Are you sure you want to continue? y
    -------------------------------------------------------------------------------------------------------------------------------------
    |                                                        DescribeStackEvents                                                        |
    +--------------------------+----------------------+-----------------------------------------+---------------------------------------+
    |  2019-12-21T13:05:44.261Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:48.351Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:48.828Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:49.187Z|  LaunchConfiguration |  AWS::AutoScaling::LaunchConfiguration  |  CREATE_COMPLETE                      |
    |  2019-12-21T13:05:51.230Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:51.837Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_IN_PROGRESS                   |
    |  2019-12-21T13:05:52.950Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  CREATE_COMPLETE                      |
    |  2019-12-21T13:05:54.493Z|  asg-prod            |  AWS::CloudFormation::Stack             |  CREATE_COMPLETE                      |
    |  2019-12-21T13:12:43.731Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_IN_PROGRESS                   |
    |  2019-12-21T13:12:48.294Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  UPDATE_IN_PROGRESS                   |
    |  2019-12-21T13:14:05.182Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  UPDATE_COMPLETE                      |
    |  2019-12-21T13:14:07.118Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_COMPLETE_CLEANUP_IN_PROGRESS  |
    |  2019-12-21T13:14:07.820Z|  asg-prod            |  AWS::CloudFormation::Stack             |  UPDATE_COMPLETE                      |
    |  2019-12-21T13:18:06.709Z|  asg-prod            |  AWS::CloudFormation::Stack             |  DELETE_IN_PROGRESS                   |
    |  2019-12-21T13:18:08.931Z|  AutoScalingGroup    |  AWS::AutoScaling::AutoScalingGroup     |  DELETE_IN_PROGRESS                   |

    An error occurred (ValidationError) when calling the DescribeStackEvents operation: Stack [asg-prod] does not exist
*Note that the error reported at the end of `stack-delete` command is just AWSCLI saying it can't find the stack anymore.*


### stack-exports



### stack-recreate



### stack-failure

Return reason a stack failed to update/create/delete


### stack-events

List event history for a single Stack

    USAGE: stack-events stack


### stack-resources

List all resources in Stack(s)

    USAGE: stack-resources stack [stack]

    $ stacks | stack-resources
    i-7d54924538baa7a1f  AWS::EC2::Instance  ec2
    i-c54279c6055c3c794  AWS::EC2::Instance  nagios
    i-a8b8dd6783e1a40cc  AWS::EC2::Instance  postgres1
    i-5d74753e210bfe04d  AWS::EC2::Instance  postgres2
    i-2aa95cc214a461398  AWS::EC2::Instance  prometheus-web


### stack-asgs

List ASGs in Stack(s)

    USAGE: stack-asgs stack [stack]

    $ stacks | stack-asgs
    asg-bash-my-aws-AutoScalingGroup-MSBCWRTI3PVM  AWS::AutoScaling::AutoScalingGroup  asg-bash-my-aws
    asg2-AutoScalingGroup-1FHUVUJ7SLPU7            AWS::AutoScaling::AutoScalingGroup  asg2


### stack-asg-instances

List EC2 Instances of EC2 Autoscaling Groups in Stack(s)

    USAGE: stack-asg-instances stack [stack]

    $ stacks | stack-asg-instances
    i-06ee900565652ecc5  ami-0119aa4d67e59007c  t3.nano  running  asg-bash-my-aws  2019-12-13T03:15:22.000Z  ap-southeast-2c  vpc-deb8edb9
    i-01c7edb986c18c16a  ami-0119aa4d67e59007c  t3.nano  running  asg2             2019-12-13T03:37:51.000Z  ap-southeast-2c  vpc-deb8edb9


### stack-elbs

List EC2 Elastic Load Balancers in Stack(s)

 USAGE: stack-elbs stack [stack]

    $ stacks | stack-elbs
    elb-MyLoadBalancer-NA5S72MLA5KI   AWS::ElasticLoadBalancing::LoadBalancer  elb-stack-1
    load-bala-MyLoadBa-11HZ0DHUHJZZI  AWS::ElasticLoadBalancing::LoadBalancer  elb-stack-2


### stack-instances

List instances in stack(s)

    USAGE: stack-instances stack [stack]

    $ stacks | stack-instances
    i-7d54924538baa7a1f  ami-123456789012  t3.nano  stopped  ec2             2019-12-11T09:31:03.000Z  ap-southeast-2a  None
    i-c54279c6055c3c794  ami-123456789012  t3.nano  running  nagios          2019-12-13T02:24:30.000Z  ap-southeast-2a  None
    i-a8b8dd6783e1a40cc  ami-123456789012  t3.nano  running  postgres1       2019-12-13T02:24:32.000Z  ap-southeast-2a  None
    i-5d74753e210bfe04d  ami-123456789012  t3.nano  running  postgres2       2019-12-13T02:24:34.000Z  ap-southeast-2a  None
    i-2aa95cc214a461398  ami-123456789012  t3.nano  running  prometheus-web  2019-12-13T02:24:36.000Z  ap-southeast-2a  None


### stack-parameters

List parameters of stack


### stack-status

List status of stack


### stack-tag

Return selected stack tag


### stack-tail

Show all events for CF stack until update completes or fails.


### stack-template

Return template of a stack


### stack-template-changeset-latest

Return template of a stack's latest changeset
Try to get the latest changeset ARN


### stack-tags

List stack-tags applied to a stack


### stack-tags-text

List stack-tags applied to a stack on a single line


### stack-outputs

List outputs of a stack


### stack-validate

Validate a stack template


### stack-diff

Compare live stack against local template (and optional params file)

    USAGE: stack-diff stack [template-file]

    $ stack-diff params/asg-params-prod.json
    Resolved arguments: asg-prod ./asg.yml params/asg-params-prod.json
    template for stack (asg-prod) and contents of file (./asg.yml) are the same

    Resolved arguments: asg-prod ./asg.yml params/asg-params-prod.json
    --- params
    +++ params/asg-params-prod.json
    @@ -1,11 +1,11 @@
     [
       {
         "ParameterKey": "AsgMaxSize",
    -    "ParameterValue": "5"
    +    "ParameterValue": "2"
       },
       {
         "ParameterKey": "AsgMinSize",
    -    "ParameterValue": "0"
    +    "ParameterValue": "1"
       },
       {
         "ParameterKey": "InstanceType",
report changes which would be made to stack if template were applied
report on what changes would be made to stack by applying params
Derive and check arguments for:

- stack-create
- stack-delete
- stack-diff

In the interests of making the functions simple and a shallow read,
it's unusual for us to abstract out shared code like this.
This bit is doing some funky stuff though and I think it deserves
to go in it's own function to DRY (Don't Repeat Yourself) it up a bit.

This function takes the unusual approach of writing to variables of the
calling function:

- stack
- template
- params

This is generally not good practice for readability and unexpected outcomes.
To contain this, the calling functions all clearly declare these three
variables as local and contain a comment that they will be set by this function.

If we are working from a single argument (ignore args starting with `--`)
Strip path and extension from template
Deduce params filename from stack and template names
Strip path and extension from template
File extension gets stripped off if template name provided as stack name
Determine name of template to use
determine name of params file to use
determine what (if any) capabilities a given stack was deployed with


## instance-commands


### instances

List EC2 Instances

    $ instances
    i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios          2019-12-10T08:17:18.000Z  ap-southeast-2a  None
    i-89cefa9403373d7a5  ami-123456789012  t3.nano  running  postgres1       2019-12-10T08:17:20.000Z  ap-southeast-2a  None
    i-806d8f1592e2a2efd  ami-123456789012  t3.nano  running  postgres2       2019-12-10T08:17:22.000Z  ap-southeast-2a  None
    i-61e86ac6be1e2c193  ami-123456789012  t3.nano  running  prometheus-web  2019-12-10T08:17:24.000Z  ap-southeast-2a  None

*Optionally provide a filter string for a `| grep` effect with tighter columisation:*

    $ instances postgres
    i-89cefa9403373d7a5  ami-123456789012  t3.nano  running  postgres1  2019-12-10T08:17:20.000Z  ap-southeast-2a  None
    i-806d8f1592e2a2efd  ami-123456789012  t3.nano  running  postgres2  2019-12-10T08:17:22.000Z  ap-southeast-2a  None


### instance-asg

List autoscaling group membership of EC2 Instance(s)

    USAGE: instance-asg instance-id [instance-id]


### instance-az

List availability zone of EC2 Instance(s)

    USAGE: instance-az instance-id [instance-id]

    $ instances postgres | instance-az
    i-89cefa9403373d7a5  ap-southeast-2a
    i-806d8f1592e2a2efd  ap-southeast-2a


### instance-console

List console output of EC2 Instance(s)

    USAGE: instance-console instance-id [instance-id]

    $ instances postgres | instance-console
    Console output for EC2 Instance i-89cefa9403373d7a5
    Linux version 2.6.16-xenU (builder@patchbat.amazonsa) (gcc version 4.0.1 20050727 (Red Hat 4.0.1-5)) #1 SMP Thu Oct 26 08:41:26 SAST 2006
    BIOS-provided physical RAM map:
    Xen: 0000000000000000 - 000000006a400000 (usable)
    ...snip...

    Console output for EC2 Instance i-806d8f1592e2a2efd
    Linux version 2.6.16-xenU (builder@patchbat.amazonsa) (gcc version 4.0.1 20050727 (Red Hat 4.0.1-5)) #1 SMP Thu Oct 26 08:41:26 SAST 2006
    BIOS-provided physical RAM map:
    Xen: 0000000000000000 - 000000006a400000 (usable)
    ...snip...


### instance-dns

List DNS name of EC2 Instance(s)

    USAGE: instance-dns instance-id [instance-id]

    $ instances postgres | instance-dns
    i-89cefa9403373d7a5  ip-10-155-35-61.ap-southeast-2.compute.internal   ec2-54-214-206-114.ap-southeast-2.compute.amazonaws.com
    i-806d8f1592e2a2efd  ip-10-178-243-63.ap-southeast-2.compute.internal  ec2-54-214-244-90.ap-southeast-2.compute.amazonaws.com


### instance-health-set-unhealthy

Mark EC2 Instance(s) as unhealthy (to trigger replacement by ASG)

    USAGE: instance-health-set-unhealthy instance-id [instance-id]


### instance-iam-profile

List iam-profile of EC2 Instance(s)

    USAGE: instance-iam-profile instance-id [instance-id]


### instance-ip

List ip address of EC2 Instance(s)

    USAGE: instance-ip instance-id [instance-id]

    $ instances postgres | instance-ip
    i-89cefa9403373d7a5  10.155.35.61   54.214.206.114
    i-806d8f1592e2a2efd  10.178.243.63  54.214.244.90


### instance-profile



### instance-profile-role



### instance-ssh

Establish SSH connection to EC2 Instance(s)

    USAGE: instance-ssh [login] [instance-id] [instance-id]


### instance-ssh-details

List details needed to SSH into EC2 Instance(s)

    USAGE: instance-ssh-details [login] [instance-id] [instance-id]


### instance-ssm

Establish SSM connection to EC2 Instance(s)

    USAGE: instance-ssm instance-id [instance-id]


### instance-rdp



### instance-ssm-port-forward

Create tunnel from localhost to remote EC2 instance

    USAGE: instance-ssm-port-forward local_port_number port_number instance-id [instance-id]


### instance-stack

List CloudFormation stack EC2 Instance(s) belong to (if any)

    USAGE: instance-stack instance-id [instance-id]

    $ instances postgres | instance-stack
    postgres1  i-89cefa9403373d7a5
    postgres2  i-806d8f1592e2a2efd


### instance-start

Start stopped EC2 Instance(s)

    USAGE: instance-start instance-id [instance-id]

    $ instances postgres | instance-start
    i-a8b8dd6783e1a40cc  PreviousState=stopped  CurrentState=pending
    i-5d74753e210bfe04d  PreviousState=stopped  CurrentState=pending


### instance-state

List state of EC2 Instance(s)

    USAGE: instance-state instance-id [instance-id]

    $ instances postgres | instance-state
    i-89cefa9403373d7a5  running
    i-806d8f1592e2a2efd  running


### instance-stop

Stop EC2 Instance(s)

    USAGE: instance-stop instance-id [instance-id]

    $ instances postgres | instance-stop

    i-a8b8dd6783e1a40cc  PreviousState=running  CurrentState=stopping
    i-5d74753e210bfe04d  PreviousState=running  CurrentState=stopping


### instance-subnet

List subnet for EC2 Instance(s)

    USAGE: instance-subnets instance-id [instance-id]


### instance-stop-protection

List current state of Stop Protection for EC2 Instance(s)

    USAGE: instance-stop-protection instance-id [instance-id]

    $ instances | instance-termination-protection
    i-4e15ece1de1a3f869 DisableApiStop=true
    i-89cefa9403373d7a5 DisableApiStop=false
    i-806d8f1592e2a2efd DisableApiStop=false
    i-61e86ac6be1e2c193 DisableApiStop=false


### instance-stop-protection-disable

Disable EC2 Instance stop protection

    USAGE: instance-stop-protection-disable instance-id [instance-id]


### instance-stop-protection-enable

Enable EC2 Instance stop protection

    USAGE: instance-stop-protection-enable instance-id [instance-id]


### instance-tags

List tags applied EC2 Instance(s)

    USAGE: instance-tags instance-id [instance-id]


### instance-tag

List named tag on EC2 Instance(s)

    USAGE: instance-tag key instance-id [instance-id]


### instance-tag-create

Create/update tag on EC2 Instance(s)

    USAGE: instance-tag-create key value instance [instance]


### instance-tag-delete

Delete tag from EC2 Instance(s)

    USAGE: instance-tag-delete key instance [instance]


### instance-terminate

Terminate EC2 Instance(s)

    USAGE: instance-terminate instance-id [instance-id]

    $ instances | head -3 | instance-terminate
    You are about to terminate the following instances:
    i-01c7edb986c18c16a  ami-0119aa4d67e59007c  t3.nano  terminated  asg2  2019-12-13T03:37:51.000Z  ap-southeast-2c  None
    i-012dded46894dfa04  ami-0119aa4d67e59007c  t3.nano  running     ec2   2019-12-13T10:12:55.000Z  ap-southeast-2b  vpc-deb8edb9
    Are you sure you want to continue? y
    i-06ee900565652ecc5  PreviousState=terminated  CurrentState=terminated
    i-01c7edb986c18c16a  PreviousState=terminated  CurrentState=terminated
    i-012dded46894dfa04  PreviousState=running     CurrentState=shutting-down


### instance-termination-protection

List current state of Termination Protection for EC2 Instance(s)

    USAGE: instance-termination-protection instance-id [instance-id]

    $ instances | instance-termination-protection
    i-4e15ece1de1a3f869 DisableApiTermination=true
    i-89cefa9403373d7a5 DisableApiTermination=false
    i-806d8f1592e2a2efd DisableApiTermination=false
    i-61e86ac6be1e2c193 DisableApiTermination=false


### instance-termination-protection-disable

Disable EC2 Instance termination protection

    USAGE: instance-termination-protection-disable instance-id [instance-id]


### instance-termination-protection-enable

Enable EC2 Instance termination protection

    USAGE: instance-termination-protection-enable instance-id [instance-id]


### instance-type

List type of instance(s)

    USAGE: instance-type instance-id [instance-id]

    $ instances | instance-type
    i-4e15ece1de1a3f869  t3.nano
    i-89cefa9403373d7a5  t3.nano
    i-806d8f1592e2a2efd  t3.nano
    i-61e86ac6be1e2c193  t3.nano


### instance-userdata

List userdata for instance(s)

    USAGE: instance-userdata instance-id [instance-id]


### instance-volumes

List volumes of instance(s)

    USAGE: instance-volumes instance-id [instance-id]

    $ instances postgres | instance-volumes
    i-89cefa9403373d7a5  vol-cf5ddae9
    i-806d8f1592e2a2efd  vol-38fd45c3


### instance-vpc

List VPC of instance(s)

    USAGE: instance-vpcs instance-id [instance-id]


## asg-commands


### asg-detach-instances

Detach all instances from asg(s)


### asgs

List EC2 Autoscaling Groups


### asg-capacity

List min, desired and maximum capacities of EC2 Autoscaling Group(s)


### asg-desired-size-set

Set desired capacity of autoscaling group(s)


### asg-instances

List instances of autoscaling group(s)


### asg-launch-configuration

List Launch Configurations of Autoscaling Group(s)


### launch-configurations

List Launch Configurations


### launch-configuration-asgs

List EC2 Autoscaling Groups of Launch Configuration(s)


### asg-max-size-set

Set maximum size of autoscaling group(s)


### asg-min-size-set

Set minimum size of autoscaling group(s)


### asg-processes_suspended

List suspended processes of an autoscaling group


### asg-resume

Resume all processes of an autoscaling group


### asg-suspend

Suspend all processes of an autoscaling group


### asg-stack

List CloudFormation stack for asg(s)


### asg-scaling-activities

List scaling activities for Autoscaling Group(s)


## azure-commands


### debug

Construct a string to be passed to `grep -E`

    foo|bar|baz


### skim-stdin-tsv



### skim-stdin-bma

Append first token from each line of STDIN to argument list

Implementation of `pipe-skimming` pattern.

    $ stacks | skim-stdin foo bar
    foo bar huginn mastodon grafana

    $ stacks
    huginn    CREATE_COMPLETE  2020-01-11T06:18:46.905Z  NEVER_UPDATED  NOT_NESTED
    mastodon  CREATE_COMPLETE  2020-01-11T06:19:31.958Z  NEVER_UPDATED  NOT_NESTED
    grafana   CREATE_COMPLETE  2020-01-11T06:19:47.001Z  NEVER_UPDATED  NOT_NESTED

Typical usage within Bash-my-AWS functions:

    local asg_names=$(skim-stdin "$@") # Append to arg list
    local asg_names=$(skim-stdin)      # Only draw from STDIN


### az-account



### az-user



### az-cache-items



### az-cache-item

Create arguments from output of az-cache-items() (if present)


### az-cache-item-delete

Create arguments from output of az-cache-items() (if present)


### locations



### location



### location-unset



### location-each



### resource-groups



### resource-group



### resource-group-export



### resource-group-unset



### resources



### resourceids



### resource-show



### resource-diff



### resource-export



### service-principals



### management-groups



### subscriptions



### subscription



### subscription-unset



### subscription-each

Ported from BMA


### ad-groups

Usage: ad-users REMOTE_STARTS_WITH_FILTER LOCAL_FILTER

REMOTE_STARTS_WITH_FILTER: filters on start of userPrincipalName
LOCAL_FILTER: grep results

[User Properties](https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0#properties)
[List Users](https://learn.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http)
columnise


### ad-group-members

List groups for AD User(s)

    USAGE: ad-user-groups USER USER # object ID or principal name of the user

    $ ad-users mike.bailey@bash-my-aws.org | ad-user-groups


### ad-users

Usage: ad-users REMOTE_STARTS_WITH_FILTER LOCAL_FILTER

REMOTE_STARTS_WITH_FILTER: filters on start of userPrincipalName
LOCAL_FILTER: grep results

[User Properties](https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0#properties)
[List Users](https://learn.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http)
columnise


### ad-user-upns



### ad-user-upns



### ad-user-names



### ad-users-graph

Usage: ad-users-graph REMOTE_STARTS_WITH_FILTER LOCAL_FILTER

REMOTE_STARTS_WITH_FILTER: filters on start of userPrincipalName
- https://learn.microsoft.com/en-us/cli/azure/format-output-azure-cli

Uses graph API - more functionaility than azcli but limited result count

$ time ad-users | wc -l
999
real    0m0.792s
user    0m0.311s
sys     0m0.047s

[User Properties](https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0#properties)
[List Users](https://learn.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http)
columnise # Disabled to preserve tabs


### ad-user-groups

List groups for AD User(s)

    USAGE: ad-user-groups USER USER # object ID or principal name of the user

    $ ad-users mike.bailey@bash-my-aws.org | ad-user-groups


### ad-user-group-diff



### ad-apps

Usage: ad-apps REMOTE_FILTER LOCAL_FILTER

REMOTE_FILTER: filters on start of displayName
LOCAL_FILTER: grep results
columnise


### ad-app

Usage: ad-app APP [APP]


### #
 ad-app-signins


### ad-app-owners

Usage: ad-app-owners APP [APP]
    --query '[].[
      appId,
      displayName,
      createdDateTime
      ]'                \
    --output tsv"       |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -b -k 3


### connectors

Usage: connectors REMOTE_FILTER LOCAL_FILTER

REMOTE_FILTER: filters on start of machineName
LOCAL_FILTER: grep results


### connector-groups

Usage: connector-groups REMOTE_FILTER LOCAL_FILTER

REMOTE_FILTER: filters on start of displayName
LOCAL_FILTER: grep results


### connector-group-apps

Usage: connector-group-apps CONNECTOR_GROUP [CONNECTOR_GROUP]


### connector-group-members

Usage: connector-group-apps CONNECTOR_GROUP [CONNECTOR_GROUP]


### deployments-group



### afds



### afd-endpoints



### afd-routes

List routes of all endpoints for Front Door Profile(s)


### afd-custom-domains



### afd-custom-domains-validation-request



### afd-origin-groups



### afd-waf-policies



### afd-waf-policy-rules



### afd-waf-policy



### afd-waf-policy-rule-match-conditions



### afd-waf-policy-rule-match-condition-values



### afd-waf-policy-rule-delete



### deployment-groups



### deployment-delete-danger



azure.azcli


## backup-commands


### backup-jobs

List Backup Jobs

Lists backup jobs with state and date created.

    $ backup-jobs
    X9B4Z0C5-R2E8-6G39-1M2P-7H8J6MPP9H8H  COMPLETED  2023-08-27T20:00:00+10:00
    Y7D1F2G1-X3B2-9H77-4N8R-2F9J4JZL8F2X  COMPLETED  2023-08-27T20:00:00+10:00


## cert-commands


### certs

List ACM Certificates


### certs-arn

Same as `certs` but with the ARN in first column


### cert-users

List resources using ACM Cert(s)

    USAGE: cert-users cert-arn [cert-arn]


### cert-delete

Delete ACM Cert(s)

    USAGE: cert-delete cert-arn [cert-arn]


### cert-ificate

Return Certificate for ACM Cert(s)

    USAGE: cert-ificate cert-arn [cert-arn]


### cert-chain

Return Cert Chain for ACM Cert(s)

    USAGE: cert-chain cert-arn [cert-arn]


### cert-resource-record-valid

cert-resource-record-valid - Check if a specified DNS resource record matches the expected value and includes input validation.

Usage: cert-resource-record-valid <name> <type> <value>
Perform the DNS query
Print the output of the DNS query
Check if the expected value is in the output


### cert-verify

Verify ACM cert(s)

    USAGE: cert-chain cert-arn [cert-arn]
Be quiet - makes it easier to scan with "cert-arns | cert_verify"


## cloudfront-commands


### distributions

List Cloudfront Distributions


## cloudtrail-commands


### cloudtrails

List Cloudtrails

    $ cloudtrails
    failmode	failmode-cloudtrail	ap-southeast-2	IsMultiRegionTrail=true	IncludeGlobalServiceEvents=true


### cloudtrail-status

List logging status of Cloudtrails

    USAGE: cloudtrail-status cloudtrail [cloudtrail]


## ecr-commands


### ecr-repositories

List ECR Repositories


### ecr-repository-images

List images for ECR Repositories


## elb-commands


### elbs

List ELBs
Accepts LoadBalancer names on STDIN and converts to LoadBalancer names

    $ elbs
    elb-MyLoadBalancer-1FNISWJN0W6N9  2019-12-13T10:24:55.220Z
    another-e-MyLoadBa-171CPCZF2E84T  2019-12-13T10:25:24.300Z


### elb-dnsname

List DNS Names of ELB(s)

     USAGE: elb-dnsname load-balancer [load-balancer]

     $ elbs | elb-dnsname
     elb-MyLoadBalancer-1FNISWJN0W6N9  elb-MyLoadBalancer-1FNISWJN0W6N9-563832045.ap-southeast-2.elb.amazonaws.com
     another-e-MyLoadBa-171CPCZF2E84T  another-e-MyLoadBa-171CPCZF2E84T-1832721930.ap-southeast-2.elb.amazonaws.com


### elb-instances

List instances of ELB(s)

     USAGE: elb-instances load-balancer [load-balancer]


### elb-stack

List CloudFormation stack names of ELB(s)

    USAGE: elb-stack load-balancer [load-balancer]

    $ elbs | elb-stack
    elb          elb-MyLoadBalancer-1FNISWJN0W6N9
    another-elb  another-e-MyLoadBa-171CPCZF2E84T


### elb-subnets

List subnets of ELB(s)

    USAGE: elb-subnets load-balancer [load-balancer]

    $ elbs | elb-subnets
    rails-demo-ELB-FRBEQPCYSZQD  subnet-5e257318 subnet-7828cd0f subnet-c25fa0a7
    huginn-ELB-BMD0QUX179PK      subnet-5e257318 subnet-7828cd0f subnet-c25fa0a7
    prometheus-ELB-C0FGVLGQ64UH  subnet-5e257318 subnet-7828cd0f subnet-c25fa0a7


### elb-azs

List Availability Zones of ELB(s)

    USAGE: elb-azs load-balancer [load-balancer]

    $ elbs | elb-azs
    rails-demo-ELB-FRBEQPCYSZQD  ap-southeast-2a ap-southeast-2b ap-southeast-2c
    huginn-ELB-BMD0QUX179PK      ap-southeast-2a ap-southeast-2b ap-southeast-2c


### elb-tags

List tags applied ELB(s)

    USAGE: elb-tags elb-id [elb-id]


### elb-tag

List named tag on ELB(s)

    USAGE: elb-tag key elb-id [elb-id]


## elbv2-commands


### elbv2s

List EC2 ELBv2 load balancers (both Network and Application types)
Accepts Load Balancer names on STDIN and converts to Network Load Balancer names

    $ elbv2s
    bash-my-aws      network      internet-facing  active        2020-01-04T11:18:49.733Z
    bash-my-aws-alb  application  internet-facing  provisioning  2020-01-04T11:29:45.030Z


### elbv2-dnsname

List DNS Names of elbv2(s)

    USAGE: elbv2-dnsname load-balancer [load-balancer]

    $ elbv2s | elbv2-dnsname
    bash-my-aws      bash-my-aws-c23c598688520e51.elb.ap-southeast-2.amazonaws.com
    bash-my-aws-alb  bash-my-aws-alb-2036199590.ap-southeast-2.elb.amazonaws.com


### elbv2-subnets

List subnets of ELBv2(s) [Application and Network Load Balancers)

    USAGE: elbv2-subnets load-balancer [load-balancer]

    $ elbv2s | elbv2-subnets
    bash-my-aws      subnet-c25fa0a7
    bash-my-aws-alb  subnet-7828cd0f subnet-c25fa0a7


### elbv2-azs

List Availability Zones of ELB(s)

    USAGE: elb-azs load-balancer [load-balancer]

    $ elbv2s | elbv2-subnets
    bash-my-aws      ap-southeast-2a
    bash-my-aws-alb  ap-southeast-2a ap-southeast-2b


### elbv2-target-groups

List target groups of ELBv2(s) [Application and Network Load Balancers)

    USAGE: elbv2-target-groups load-balancer [load-balancer]

    $ elbv2s | elbv2-target-groups
    bash-my-aws-nlb-tg  TCP   22   vpc-018d9739  bash-my-aws-nlb
    bash-my-aws-alb-tg  HTTP  443  vpc-018d9739  bash-my-aws-alb


## iam-commands


### iam-roles

List IAM Roles

    $ iam-roles
    config-role-ap-southeast-2               AROAI3QHAU3J2CDRNLQHD  2017-02-02T03:03:02Z
    AWSBatchServiceRole                      AROAJJWRGUPTRXTV52TED  2017-03-09T05:31:39Z
    ecsInstanceRole                          AROAJFQ3WMZXESGIKW5YD  2017-03-09T05:31:39Z


### iam-role-principal

List role principal for IAM Role(s)

    USAGE: iam-role-principal role-name [role-name]


### iam-users

List IAM Users

    $ iam-users
    config-role-ap-southeast-2               AROAI3QHAU3J2CDRNLQHD  2017-02-02T03:03:02Z
    AWSBatchServiceRole                      AROAJJWRGUPTRXTV52TED  2017-03-09T05:31:39Z
    ecsInstanceRole                          AROAJFQ3WMZXESGIKW5YD  2017-03-09T05:31:39Z


### iam-access-key-rotate



## image-commands


### images

List EC2 AMI's

Usage: images [owner] [image-id] [image-id]...

owner defaults to `self` or can one or more of:

- an AWS_ACCOUNT_ID  (e.g. 1234567890)
- an AWS_OWNER_ALIAS (amazon, amazon-marketplace, microsoft)

image_id can be one or more AMIs

Trialing a different approach for grabbing resource ids from input.
As normal, you can pipe resource ids in as first token on each line.
We treat all args that don't start with ami- as owner identifiers.

Trialing a new pattern for output - putting the Name at the end.
This is more like the output of `ls -la`

- Pro: Preceding fields tend to be of the same length
- Pro: Easier for eyes to scan final column for names(?)
- Con: Using this pattern for instances() would put name past 80 char point
- Con: Migrating instances() to this output is A Big Change (not made lightly)


### image-deregister

Deregister AMI(s)

    USAGE: image-deregister image_id [image_id]


## keypair-commands


### keypairs

List EC2 SSH Keypairs in current Region

    $ keypairs
    alice  8f:85:9a:1e:6c:76:29:34:37:45:de:7f:8d:f9:70:eb
    bob    56:73:29:c2:ad:7b:6f:b6:f2:f3:b4:de:e4:2b:12:d4


### keypair-create

Create SSH Keypair on local machine and import public key into new EC2 Keypair.

Provides benefits over AWS creating the keypair:

- Amazon never has access to private key.
- Private key is protected with passphrase before being written to disk.
- Keys is written to ~/.ssh with correct file permissions.
- You control the SSH Key type (algorithm, length, etc).

    USAGE: keypair-create [key_name] [key_dir]

    $ keypair-create yet-another-keypair
    Creating /home/m/.ssh/yet-another-keypair
    Generating public/private rsa key pair.
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/m/.ssh/yet-another-keypair.
    Your public key has been saved in /home/m/.ssh/yet-another-keypair.pub.
    The key fingerprint is:
    SHA256:zIpbxLo7rpQvKyezOLATk96B1kSL0QP41q6x8tUrySk m@localhost.localdomain
    The key's randomart image is:
    +---[RSA 4096]----+
    |..o              |
    |.. +             |
    | .+.o            |
    | .oo.. o         |
    | o+.  o S        |
    |=o.+.= .         |
    |+++==o+          |
    |XoE+*+ .         |
    |o@+**+.          |
    +----[SHA256]-----+
    {
        "KeyFingerprint": "21:82:f9:5b:79:d6:dc:0f:7b:79:43:7c:c5:34:6c:2d",
        "KeyName": "yet-another-keypair"
    }

!!! Note
    KeyPair Name defaults to "$(aws-account-alias)-$(region)" if none provided


### keypair-delete

Delete EC2 SSH Keypairs by providing their names as arguments or via STDIN

    USAGE: keypair-delete key_name [key_name]

    $ keypair-delete alice bob
    You are about to delete the following EC2 SSH KeyPairs:
    alice
    bob
    Are you sure you want to continue? y

    $ keypairs | keypair-delete
    You are about to delete the following EC2 SSH KeyPairs:
    yet-another-keypair
    Are you sure you want to continue? y


## kms-commands


### kms-encrypt

Encrypt and base64 encode STDIN or file

    USAGE: kms-encrypt key_id/alias_id [plaintext_file]

    $ echo foobar | kms-encrypt alias/default
    AQICAHgcyN4vd3V/OB7NKI6IMbpENEu1+UfyiU...


### kms-decrypt

base64 decode and decrypt KMS Encrypted file or STDIN

    USAGE: kms-decrypt [ciphertext_file]

    $ kms-decrypt ciphertext.txt
    foobar

    $ echo foobar | kms-encrypt alias/default | kms-decrypt
    foobar


### kms-aliases

List KMS Aliases

    $ kms-aliases default
    alias/default  d714a175-db12-4574-8f27-aa071a1dfd8a  arn:aws:kms:ap-southeast-2:089834043791:alias/default


### kms-alias-create

Create alias for KMS Key

    USAGE: kms-alias-create alias_name key_id

    $ kms-keys | tail -1
    d714a175-db12-4574-8f27-aa071a1dfd8a

    $ kms-keys | tail -1 | kms-alias-create alias/foobar

    $ kms-aliases foobar
    alias/foobar  d714a175-db12-4574-8f27-aa071a1dfd8a  arn:aws:kms:ap-southeast-2:089834043791:alias/foobar


### kms-alias-delete

Delete alias for KMS Key

    USAGE: kms-alias-delete alias_name [alias_name]

    $ kms-aliases foobar | kms-alias-delete
    You are about to delete the following kms aliases:
    alias/foobar
    Are you sure you want to continue? y


### kms-keys

List KMS Keys

    $ kms-keys
    5044958c-151d-4995-bed4-dd05c1385b48
    8ada3e65-e377-4435-a709-fbe75dfa1dd0
    d714a175-db12-4574-8f27-aa071a1dfd8a


### kms-key-create

Create a KMS Key

    $ kms-key-create
    9e94333b-8e85-497a-9791-e7c5edf9c35e


### kms-key-details

List details for KMS Key(s)


### kms-key-disable

Disable KMS Key(s)

    USAGE: kms-key-disable key_id [key_id]

    $ kms-key-disable  9e94333b-8e85-497a-9791-e7c5edf9c35e


### kms-key-enable

Enable KMS Key(s)

    USAGE: kms-key-enable key_id [key_id]

    $ kms-key-enable  9e94333b-8e85-497a-9791-e7c5edf9c35e


## lambda-commands


### lambda-functions

List lambda functions

    $ lambda-functions
    stars    2019-12-18T10:00:00.000+0000  python2.7  256
    stripes  2019-12-19T10:21:42.444+0000  python3.7  128


### lambda-function-memory

List memorySize for lambda function(s)

    USAGE: lambda-function-memory function [function]


### lambda-function-memory-set

Update memorySize for lambda function(s)

    USAGE: lambda-function-memory-set memory function [function]


### lambda-function-memory-step

Repeatedly update memorySize for lambda function(s)

Useful for measuring impact of memory on cost/performance.
The function increases memorySize by 64KB every two minutes
until it reaches the value requested. There is a two minute
delay between increases to provide time to collect data from
function execution.

    USAGE: lambda-function-memory-step memory function [function]


### lambda-function-logs



## log-commands


### log-groups

List CloudWatch Log Groups

    $ log-groups
    /aws/lambda/stars2  1576495961429  0   11736
    /aws/lambda/stars   1576566745961  0  107460
    /aws/lambda/walk    1576567300172  0   11794


### log-group-delete

Delete CloudWatch Log Group

    $ log-group-delete /aws/lambda/stars
    You are about to delete the following log groups?
    /aws/lambda/stars
    Are you sure? [y/N] y
    Deleting: /aws/lambda/stars
    Deleted: /aws/lambda/stars
    
    You can also pipe the log group names to this command
    $ log-groups | log-group-delete


## rds-commands


### rds-db-instances

List RDS Database Instances
Tip: Filter on whether DB is in cluster with: `awk -F'\t' '$6 != "None"'`


### rds-db-clusters

List RDS Database Clusters


## route53-commands


### hosted-zones

List Route53 Hosted Zones

    $ hosted-zones
    /hostedzone/Z3333333333333  5   NotPrivateZone  bash-my-aws.org.
    /hostedzone/Z5555555555555  2   NotPrivateZone  bash-my-universe.com.
    /hostedzone/Z4444444444444  3   NotPrivateZone  bashmyaws.org.
    /hostedzone/Z1111111111111  3   NotPrivateZone  bash-my-aws.com.
    /hostedzone/Z2222222222222  3   NotPrivateZone  bashmyaws.com.


### hosted-zone-ns-records

Generate NS records for delegating domain to AWS

    $ hosted-zones bash-my-aws.org
    /hostedzone/ZJ6ZCG2UD6OKX  5  NotPrivateZone  bash-my-aws.org.

    $ hosted-zones bash-my-aws.org | hosted-zone-ns-records
    bash-my-aws.org. 300 IN NS	ns-786.awsdns-34.net.
    bash-my-aws.org. 300 IN NS	ns-1549.awsdns-01.co.uk.
    bash-my-aws.org. 300 IN NS	ns-362.awsdns-45.com.
    bash-my-aws.org. 300 IN NS	ns-1464.awsdns-55.org.


## s3-commands


### buckets

List S3 Buckets

    $ buckets
    web-assets  2019-12-20  08:24:38.182045
    backups     2019-12-20  08:24:44.351215
    archive     2019-12-20  08:24:57.567652


### bucket-acls

List S3 Bucket Access Control Lists.

    $ bucket-acls another-example-bucket
    another-example-bucket

!!! Note
    The only recommended use case for the bucket ACL is to grant write
    permission to the Amazon S3 Log Delivery group to write access log
    objects to your bucket. [AWS docs](https://docs.aws.amazon.com/AmazonS3/latest/dev/access-policy-alternatives-guidelines.html)


### bucket-remove

Remove an empty S3 Bucket.

*In this example the bucket is not empty.*

    $ bucket-remove another-example-bucket
    You are about to remove the following buckets:
    another-example-bucket  2019-12-07  06:51:12.022496
    Are you sure you want to continue? y
    remove_bucket failed: s3://another-example-bucket An error occurred (BucketNotEmpty) when calling the DeleteBucket operation: The bucket you tried to delete is not empty


### bucket-remove-force

Remove an S3 Bucket, and delete all objects if it's not empty.

    $ bucket-remove-force another-example-bucket
    You are about to delete all objects from and remove the following buckets:
    another-example-bucket  2019-12-07  06:51:12.022496
    Are you sure you want to continue? y
    delete: s3://another-example-bucket/aliases
    remove_bucket: another-example-bucket


## secretsmanager-commands


### secrets



## ssm-commands


### ssm-instances

List Instances known to SSM

   USAGE: ssm-instances [filter]

   $ ssm-instances
   i-00a123b456d789012  Online  Amazon Linux                              2           192.168.1.10    server001.example.com
   i-01b234c567e890123  Online  Microsoft Windows Server 2019 Datacenter  10.0.17763  192.168.1.20    winserver002.example.com
   i-02c345d678f901234  Online  Ubuntu                                    20.04       192.168.1.30    ubuntu003.example.com
   i-03d456e789a012345  Online  Ubuntu                                    20.04       192.168.1.40    ubuntu004.example.com
   i-04e567f89b1234567  Online  Amazon Linux                              2           192.168.1.50    server005.example.com
   *Optionally provide a filter string for a `| grep` effect with tighter columisation:*

   $ ssm-instances Windows
   i-00a123b456d789012 Online  Microsoft Windows Server 2019 Datacenter  68.0.11111  192.168.1.10    server001.example.com
   i-01b234c567e890123 Online  Microsoft Windows Server 2022 Datacenter  68.0.11112  192.168.1.20    winserver002.example.com


### ssm-send-command

Run a command locally on EC2 instance(s) running Linux

    USAGE: ssm-send-command COMMAND instance-id [instance-id]

    $ ssm-send-command 'date +%F' i-0fict1234abcd
    Command ID: 12345abc-de67-f890-gh12-34ij56kl789m
    Waiting for command to complete...
    i-0fict1234abcd  2023-12-01

    $ ssm-instances | grep Linux | ssm-send-command 'date +%F'
    Command ID: 98b7c6d2-e3f4-11ac-8d20-47a56db09c8f
    Waiting for command to complete...
    i-0fake1234a567bcd  2023-12-01
    i-0fake2345b678cde  2023-12-01
    i-0fake3456c789def  2023-11-30
    i-0fake4567d890efa  2023-11-30
    i-0fake5678e901fgh  2023-12-01
    i-0fake6789f012ghi  2023-12-01

    See also: ssm-send-command-windows
Escape double quotes in command
Send command


### ssm-send-command-windows

Run a command locally on EC2 instance(s) running Windows

    USAGE: ssm-send-command-windows COMMAND instance-id [instance-id]

    $ ssm-send-command 'Get-Hotfix' i-0fict1234abcd
    Command ID: 12345abc-de67-f890-gh12-34ij56kl789m
    Waiting for command to complete...
    i-0fict1234abcd  2023-12-01

    $ ssm-instances Windows | ssm-send-command-windows Get-Hotfix
    Command ID: a0eeeddc-2edf-42bc-b0c7-122f5bc50956
    Waiting for command to complete...
    i-0fake1234abcd                                                                           
       Source        Description      HotFixID      InstalledBy          InstalledOn              
       ------        -----------      --------      -----------          -----------              
       FAKEAPP01234  Update           KB1234567     NT AUTHORITY\SYSTEM  10/11/2023 12:00:00 AM   
       FAKEAPP01234  Update           KB8901234     NT AUTHORITY\SYSTEM  12/12/2018 12:00:00 AM   
       FAKEAPP01234  Security Update  KB5678901     NT AUTHORITY\SYSTEM  12/12/2018 12:00:00 AM   
       FAKEAPP01234  Update           KB2345678     NT AUTHORITY\SYSTEM  1/9/2019 12:00:00 AM     
       FAKEAPP01234  Update           KB3456789     NT AUTHORITY\SYSTEM  3/11/2021 12:00:00 AM    
       FAKEAPP01234  Security Update  KB4567890     NT AUTHORITY\SYSTEM  4/21/2019 12:00:00 AM    
       FAKEAPP01234  Security Update  KB5678901     NT AUTHORITY\SYSTEM  5/15/2019 12:00:00 AM    
       FAKEAPP01234  Security Update  KB6789012     NT AUTHORITY\SYSTEM  6/12/2019 12:00:00 AM   
    ---Output truncated---                                                                        
    i-0fake1234abcd                                                                           
       Source        Description      HotFixID      InstalledBy          InstalledOn              
       ------        -----------      --------      -----------          -----------              
       FAKEAPP01234  Update           KB1234567     NT AUTHORITY\SYSTEM  10/11/2023 12:00:00 AM   
       FAKEAPP01234  Update           KB8901234     NT AUTHORITY\SYSTEM  12/12/2018 12:00:00 AM   
       FAKEAPP01234  Security Update  KB5678901     NT AUTHORITY\SYSTEM  12/12/2018 12:00:00 AM   

    See also: ssm-send-command-windows


### ssm-automation-executions

List recent SSM Automation Executions
USAGE: ssm-automation-executions [filter]

    $ ssm-automation-executions
    1234abcd-ef56-7890-gh12-ijk3456lmnop  UpdateAndSecureNodes    None                 Failed   2023-07-20T09:00:00.000000+00:00  None
    5678efgh-ijkl-9012-mnop-qrstuvwx3456  UpdateAndSecureNodes    i-0a1b2c3d4e5f67890  Failed   2023-07-20T09:00:10.000000+00:00  None
    90abijkl-mnop-4567-qrst-uvwxyza12345  UpdateAndSecureNodes    i-1b2c3d4e5f6g78901  Failed   2023-07-20T09:00:20.000000+00:00  None
    cdefmnop-qrst-8910-uvwx-yzab1234cdef  UpdateAndSecureNodes    i-2c3d4e5f6g7h89012  Failed   2023-07-20T09:00:30.000000+00:00  None
    ghijqrst-uvwx-2345-yzab-abcd5678efgh  UpdateAndSecureNodes    i-3d4e5f6g7h8i90123  Failed   2023-07-20T09:00:40.000000+00:00  None


### ssm-automation-execution-failures



### ssm-automation-step-executions

Show step-by-step details for an SSM Automation Execution

    USAGE: automation-execution-steps execution_id [execution_id]

    $ ssm-automation-executions | ssm-automation-steps-executions
    [Outputs detailed step information for each provided execution ID]


### ssm-automation-execution

Show details for an SSM Automation Execution

    USAGE: ssm-automation-execution execution_id [execution_id]

    $ ssm-automation-executions | head | ssm-automation-execution
    1234abcd-5678-9def-ghij-klmnopqrstuv  DeployNewFeatures  i-01234a5b6c7d8e9f0  Failed  2023-09-10T10:10:10.000000+00:00  2023-09-10T10:10:20.000000+00:00
    9876fedc-ba98-7654-c321-onmlkjihgfed  DeployNewFeatures  i-09876b5c4d3e2f1g0  Failed  2023-09-10T10:20:30.000000+00:00  2023-09-10T10:20:40.000000+00:00
    abcd1234-efgh-5678-ijkl-9mnopq7rstuv  DeployNewFeatures  i-0a1b2c3d4e5f6g7h8  Failed  2023-09-10T10:30:50.000000+00:00  2023-09-10T10:31:00.000000+00:00
    ijkl8765-ghij-4321-klmn-5opq4rstu3vw  DeployNewFeatures  i-0i8j7k6l5m4n3o2p1  Failed  2023-09-10T10:40:10.000000+00:00  2023-09-10T10:40:20.000000+00:00


### ssm-associations

List SSM associations

    USAGE: ssm-associations [filter]

    $ ssm-associations
    Task-RunSecurityScan                cron(30 2 * * SUN)    2023-01-15T02:30:00.000000+00:00  Failed
    Task-UpdateSystemPackages           cron(0 4 * * SAT)     2023-04-22T04:00:00.000000+00:00  Success
    Service-ConfigureNetworkSettings    rate(7 days)          2023-05-07T11:00:00.000000+00:00  Success
    Script-DeployMonitoringTools        cron(15 3 * * FRI)    2023-03-03T03:15:00.000000+00:00  Failed


### ssm-association-executions

List SSM Association Executions

    USAGE: ssm-associations [filter]

    $ ssm-associations
    12345678-9abc-def0-1234-56789abcdef0  a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890  Success  {Success=10}  2023-07-21T10:30:00.000000+00:00
    12345678-9abc-def0-1234-56789abcdef0  b1c2d3e4-f5g6-7890-b1c2-d3e4f5g67890  Success  {Success=15}  2023-07-22T11:00:00.000000+00:00
    12345678-9abc-def0-1234-56789abcdef0  c1d2e3f4-g5h6-7890-c1d2-e3f4g5h67890  Success  {Success=13}  2023-07-23T09:45:00.000000+00:00
    12345678-9abc-def0-1234-56789abcdef0  d1e2f3g4-h5i6-7890-d1e2-f3g4h5i67890  Failed   {Failed=2, Success=12} 2023-07-24T12:30:00.000000+00:00
    12345678-9abc-def0-1234-56789abcdef0  e1f2g3h4-i5j6-7890-e1f2-g3h4i5j67890  Failed   {Failed=3, Success=11}  2023-07-25T14:15:00.000000+00:00


### ssm-association-execution-targets

List targets for SSM Association Execution

    USAGE: ssm-association-execution-targets association-id execution-id

    $ association-execution-targets abcd1234-ef56-7890-gh12-ijk3456lmnop  12345678-90ab-cdef-1234-567890abcdef
    abcd1234-ef56-7890-gh12-ijk3456lmnop  12345678-90ab-cdef-1234-567890abcdef  i-01234abcde56789f0  Success  Success  2023-08-10T11:30:00.000000+00:00
    abcd1234-ef56-7890-gh12-ijk3456lmnop  12345678-90ab-cdef-1234-567890abcdef  i-02345bcdef67891g1  Success  Success  2023-08-10T11:30:10.000000+00:00
    abcd1234-ef56-7890-gh12-ijk3456lmnop  12345678-90ab-cdef-1234-567890abcdef  i-03456cdefg78912h2  Success  Success  2023-08-10T11:30:20.000000+00:00
    abcd1234-ef56-7890-gh12-ijk3456lmnop  12345678-90ab-cdef-1234-567890abcdef  i-04567defgh89123i3  Success  Success  2023-08-10T11:30:30.000000+00:00

Note: Can't use skim-stdin as it requires to arguments


### ssm-parameters

List SSM Parameters

   USAGE: ssm-parameters [filter]

   $ ssm-parameters
   /company/ad/a1234567/username
   /ami/Ubuntu-20.04-proxy
   /cloudwatch-agent/config/general
   /cnf/staticSite/B1P2V34SR5KF0Z/encryptionKeyArn
   /ops/CloudMetrics/linux
   /ops/CloudMetrics/windows


### ssm-parameter-value

Print SSM Parameter Value

   USAGE: ssm-parameter-value ssm-parameter [ssm-parameter]

   $ ssm-parameters | ssm-parameter-value
   /ops/Monitoring/metrics/unix
   {
     "agent": {
       "metrics_collection_interval": 60,
       "logfile": "/var/log/aws-monitoring/aws-monitoring-agent.log"
     },
     "logs": {
       "logs_collected": {
         "files": {
   <snip>


### instance-ssm-platform-type

Show platform type (OS) for instance

    USAGE: instance-ssm-platform-type instance-id [instance-id]

    $ instances | instance-ssm-platform-type
    i-0c1d2e3f4a567890b     None
    i-0d1c2b3a4e5f6789c     Linux
    i-0e1f2d3c4b5a6789d     Linux
    i-0f1e2d3c4b5a6789e     None
    i-0a9f8e7d6c5b4a312     None
    i-01b2a3c4d5e6f7893     Windows


## sts-commands


### sts-assume-role

Assume an IAM Role

    USAGE: sts-assume-role role_arn


## tag-commands


### tag-keys

List unique set of tag keys in AWS Account / Region

    USAGE: tag-keys


### tag-values

List unique set of tag values for key in AWS Account / Region

    USAGE: tag-values key


## target-group-commands


### target-groups

List EC2 ELBv2 target groups

    $ target-groups
    bash-my-aws-nlb-tg  TCP   22   vpc-04636ebe5573f6f65  instance  bash-my-aws-nlb
    bash-my-aws-alb-tg  HTTP  443  vpc-04636ebe5573f6f65  instance  bash-my-aws-alb


### target-group-targets

List EC2 ELBv2 target group targets
Accepts Target Group names on stdin or as arguments

    $ target-group-targets bash-my-aws-nlb-tg
    i-4e15ece1de1a3f869  443  healthy    bash-my-aws-nlb-tg
    i-89cefa9403373d7a5  443  unhealthy  bash-my-aws-nlb-tg


## vpc-commands


### pcxs

List VPC Peering connections


### subnets

List subnets for all VPCs

    $ subnets
    subnet-34fd9cfa  vpc-018d9739  ap-southeast-2c  172.31.32.0/20  NO_NAME
    subnet-8bb774fe  vpc-018d9739  ap-southeast-2a  172.31.0.0/20   NO_NAME
    subnet-9eea2c07  vpc-018d9739  ap-southeast-2b  172.31.16.0/20  NO_NAME


### vpcs

List VPCs

    $ vpcs
    vpc-018d9739  default-vpc  NO_NAME  172.31.0.0/16  NO_STACK  NO_VERSION


### vpc-azs

List availability zones of VPC(s)

    USAGE: vpc-azs vpc-id [vpc-id]

    $ vpcs | vpc-azs
    vpc-018d9739 ap-southeast-2a ap-southeast-2b ap-southeast-2c


### vpc-az-count

List number of Availability Zones of VPC(s)

    USAGE: vpc-az-count vpc-id [vpc-id]

    $ vpcs | vpc-az-count
    vpc-018d9739 3


### vpc-lambda-functions

List lambda functions of VPC(s)

    USAGE: vpc-lambda-functions vpc-id [vpc-id]


### vpc-dhcp-options-ntp

List NTP servers of VPC(s)

    USAGE: vpc-dhcp-options-ntp vpc-id [vpc-id]


### vpc-endpoints

List VPC Endpoints

    USAGE: vpc-endpoints [filter]


### vpc-endpoint-services

List available VPC endpoint services

    USAGE: vpc-endpoint-services


### vpc-igw

List Internet Gateway of VPC(s)

    USAGE: vpc-igw vpc-id [vpc-id]


### vpc-route-tables

List Route Tables of VPC(s)

    USAGE: vpc-route-tables vpc-id [vpc-id]

    $ vpcs | vpc-route-tables
    rtb-8e841c39  vpc-018d9739  NO_NAME


### vpc-nat-gateways

List NAT Gateways of VPC(s)

    USAGE: vpc-nat-gateways vpc-id [vpc-id]


### vpc-subnets

List subnets of VPC(s)

    USAGE: vpc-subnets vpc-id [vpc-id]

    $ vpcs | vpc-subnets
    subnet-34fd9cfa  vpc-018d9739  ap-southeast-2c  172.31.32.0/20  NO_NAME
    subnet-8bb774fe  vpc-018d9739  ap-southeast-2a  172.31.0.0/20   NO_NAME
    subnet-9eea2c07  vpc-018d9739  ap-southeast-2b  172.31.16.0/20  NO_NAME


### vpc-network-acls

List Network ACLs of VPC(s)

    USAGE: vpc-network-acls vpc-id [vpc-id]

    $ vpcs | vpc-network-acls
    acl-ff4914d1  vpc-018d9739


### vpc-rds

List RDS instances of VPC(s)

    USAGE: vpc-rds vpc-id [vpc-id]


### vpc-default-delete

Print commands you would need to run to delete that pesky default VPC
Exclude default VPCs that contain:
- instances
- lambda functions

    $ vpc-default-delete

    # Deleting default VPC vpc-018d9739 in ap-southeast-2
    aws --region ap-southeast-2 ec2 delete-subnet --subnet-id=subnet-8bb774fe
    aws --region ap-southeast-2 ec2 delete-subnet --subnet-id=subnet-9eea2c07
    aws --region ap-southeast-2 ec2 delete-subnet --subnet-id=subnet-34fd9cfa
    aws --region ap-southeast-2 ec2 delete-vpc --vpc-id=vpc-018d9739
