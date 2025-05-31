# bash-my-aws development guide.

There are three distinct classes of functions types within `bash-my-aws`;
*query*, *detail*, and *action* functions.

Query functions are responsible for requesting AWS return a list of resources
by their unique identifier. That would mean that when querying EC2 instances,
it should return a list of instance-ids. If we were to query CloudFormation,
then stacks are what would be returned.

Detail functions should provide you an output of one or more attributes.

eg. instance-asg(), instance-state()

Action functions should perform an action against a resource. An action for an
EC2 instance may be something like *terminate* or *associate_eip*.

e.g. stack-create(), instance-terminate(), asg-suspend()

## Function Templates and Implementation Guide

For detailed implementation guidance, refer to these resources:

- **[Function Taxonomy](function-taxonomy.md)** - Comprehensive classification of function types, naming conventions, and usage patterns
- **[Function Templates](function-templates/)** - Copy-paste ready templates for each function type:
  - `query-function-template.sh` - For resource listing functions
  - `detail-function-template.sh` - For resource attribute functions  
  - `action-function-template.sh` - For resource operation functions
- **[Header Implementation Guide](implementing-headers-guide.md)** - How to add column headers to functions
- **[Implementation Checklist](header-implementation-checklist.md)** - Quick reference for function development

These templates include comprehensive examples, common patterns, error handling, and customization checklists to ensure consistent implementation across all bash-my-aws functions.

There are some great things about `bash-my-aws` which I would hate to lose.

* It's easy to look at the code and learn how `awscli` works.
* Simple tasks have simple commands.
* It's really easy to extend.

stdin should always be supported. You should be able to pipe one function into
the next with ease. If an action function cannot be piped the output of a query
function and have it work, without manipulation though other tools, then
something is wrong.

## Namespacing

We've decided to namespace functions by the resource they're concerned with.
Yes, this may seem a bit like postgres naming their command createdb but that's
OK. bash-my-aws reduces my keystrokes. We'll work something out if this becomes
a problem.

```
stack-asgs        stack-elbs        stack-outputs     stack-tags      stack-validate
stack-create      stack-events      stack-parameters  stack-tail      stacks
stack-delete      stack-failure     stack-resources   stack-template
stack-diff        stack-instances   stack-status      stack-update
```

```
instance-asg          instance-ssh          instance-stop         instance-volumes
instance-console      instance-ssh-details  instance-tags         instances
instance-dns          instance-stack        instance-terminate
instance-iam-profile  instance-start        instance-type
instance-ip           instance-state        instance-userdata
```

```
asg-capacity             asg-max-size-set         asg-resume               asgs
asg-desired-size-set     asg-min-size-set         asg-suspend
asg-instances            asg-processes_suspended  asgard
```



## Resources

This is a partial list of resources, with possible alternative names in brackets.

- asg               (autoscaling_group)
- bucket
- elb               (load_balancer)
- instance
- instance_type
- rds               (relational_database)
- dynamodb          (relational_database)
- sg                (security_group)
- stack             (cloudformation_stack)


## Query Functions

Query functions are always namespaced under the plural of the resource.

### Default Query

TODO: lets talk about the details.

Some example usage of this function would be:

    $ <resources>
    resource_id1  attribute attribute
    resource_id2  attribute attribute
    resource_id3  attribute attribute


## Detail Functions

Detail functions are always namespaced under the singular of the resource.

Some example usage of this function would be:

    $ <resource> <resource_id>
    attribute1: value1
    attribute2: value2

Some example responses:

    $ instance_security_groups i-abcd1234
    sg-00000001 i-abcd1234
    sg-00000002 i-abcd1234
    sg-00000003 i-abcd1234
    sg-00000004 i-abcd1234

    $ security_group_rules
    TODO: I'm not sure yet how to present a security group rule.

    $ instance_type i-abcd1234
    c3.large i-abcd1234

    $ instance_type_memory c3.large
    3.75 c3.large



## Action Functions

Action functions are always namespaced under the singular of the resource and are suffixed with the action they are responsible for undertaking.

Some example usage of this function would be:

    $ <resource>_<action> <resource_id>


## Tests

You can start the test suite by running the command `make test`.


## STDIN

* The first word of each line must be a resource.
* Additional information will be disregarded.
