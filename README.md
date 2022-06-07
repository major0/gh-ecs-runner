Dockerized GitHub Runner
========================

Deploy ephemeral/one-shot containerized [GitHub Runner][]s which can be
leveraged from a [GitHub Workflow][].  This allows dynamic deployment of
[GitHub Runner][]s which have access to your deployment environment w/out the
need to install dedicated agents into your network.  This is useful for
performing such actions as running automated testing from [GitHub][] against
private infrastructure, database migration scripts, infrastructure deploys,
etc.

How it Works
------------

The basics idea is that we are deploying a pre-existing container image which
already has the [GitHub Runner][] installed.  The container startup script
simply facilitates the automatic registration of the runner as an
ephemeral/one-shot agent.

As part of startup the base image performs the following actions:

1. Lookup the appropriate `<organization>/<repository>` registration URL based
   on `env` variables.
2. Register itself with [GitHub][] as an _ephemeral_ [GitHub Runner][].
3. [GitHub Runner][] begins polling the currently running [GitHub Workflow][]
   looking for work.
4. Once all work in the workflow is done, [GitHub][] will inform the runner
   that there is nothing left to do and that the runner can terminate.
5. The [GitHub Runner][] will automatically de-register itself.

Requirements
------------

There are a few dependancies that must be setup in the target environment
before this can be made to really work.

1. [Personal Access Token][GitHub PAT] with the appropriate permissions.
2. An existing container image in a container registry accessible to the target
   environment.  E.g. [Docker Hub][], [AWS ECR][], etc.
3. Necessary access credentials for launching a container w/in the target
   environment.  E.g. [AWS Access Keys][AWS Security].
4. An existing job/task definition w/in the target environment.  I.e. for
   [AWS][] there should be an existing [ECS Task][] definition which the
   workflow can launch.

_note: While it is technically possible to allow the workflow to define a
job/task to launch on its own, this would allow a workflow to launch arbitrary
applications into the target w/ little-to-no constraints._


Example
-------

A simple example on launching the runner:

```
jobs:
  runner:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      repository-projects: write
    outputs:
      id: ${{ steps.runner.outputs.runner_id }}
      arn: ${{ steps.runner.outputs.task_arn }}
      ipaddr: ${{ steps.runner.outputs.ipaddr }}
    steps:

    # Can leverage GitHub OIDC to AWS
    # See: https://github.com/aws-actions/configure-aws-credentials
    - id: credentials
      name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
	role-session-name: MyDeploymentWorkflow
        aws-region: us-west-2

    - id: runner
      uses: major0/gh-ecs-runner@master
      with:
        name: techops-runner
        subnets-tag: placement:ecs
        token: ${{ secrets.runner-token }}
        labels: dev

  do-stuff:
    needs: runner
    runs-on: ["self-hosted", "Linux", "X64", "ephemeral", "dev", "${{ needs.runner.outputs.id }}"]
    permissions:
      id-token: write
      repository-projects: read
    steps:

    # See: https://github.com/actions/checkout
    - uses: actions/checkout@v3
      with:
        ssh-key: ${{ secrets.ssh-key }}

    # (optional) switch to different AWS credentials
    - id: credentials
      name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    - id: my-stuff
      run: |
        # This runs in AWS on the GitHub Runner
	echo "Hello World"
```

See: [action.yaml](action.yaml) for input paramters.

[//]: # (Begin Common Mark document references)

[AWS]: https://aws.amazon.com/
[AWS ECS]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
[AWS ECR]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
[AWS Security]: https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html
[Docker Hub]: https://hub.docker.com/
[ECS Task]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
[ECS Service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
[GitHub]: https://www.github.com/
[GitHub Runner]: https://docs.github.com/en/actions/hosting-your-own-runners
[GitHub Workflow]: https://docs.github.com/en/get-started/getting-started-with-git/git-workflows
[GitHub PAT]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
