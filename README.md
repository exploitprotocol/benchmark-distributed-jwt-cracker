# benchmark-distributed-jwt-cracker

This repository contains the source code used to benchmark [distributed-jwt-cracker](https://github.com/lmammino/distributed-jwt-cracker).


## Current results

| Secret length | Attempts            | Time              |
| ------------: |:------------------- | -----------------:|
|             5 | 26^5 = **12 mln**   | 1m55.618s         |
|             6 | 26^6 = **310 mln**  | 1h32m48.378s      |
|             7 | 26^7 = **8 Bln**    | 3d18h22m10.231s   |
|             8 | 26^8 = **210 Bln**  | TODO              |
|             9 | 26^9 = **5.5 Tln**  | TODO              |


## The benchmark

This benchmark will spin up a number of virtual machine on AWS in order to crack a given JWT token. This is the default setup:

  - 1 `t2.medium` running 1 **server** process
  - 4 `t2.medium` running 2 **client** processes each

Once the computation is completed the results will be logged in CloudWatch (log stream) and the machines will be automatically destroyed.

Note: the benchmark is currently hardcoded to run in `eu-west-1` (Ireland region).


## Requirements

  - An [AWS account](https://aws.amazon.com/free/) and a user (with full programmatic access configured in the local machine through [`aws-cli`](https://aws.amazon.com/cli/))
  - [Packer](https://www.packer.io)
  - [Terraform](https://www.terraform.io)


## Build the AMI

The AMI that contains the necessary software can be built using packer by running:

```bash
packer build images/packer-ami.json
```

This will spin up a `t2.micro` instance in your AWS account, build the image, destroy the machine and finally publish the new AMI.

You will get the id of the AMI as part of the command output in case of success.


## Configuration

Before you can run the benchmark suite you have to create a terraform configuration file. You can start by copying the sample configuration file:

```bash
cp terraform.tfvars{~sample,}
```

In the newly created `terraform.tfvars` you can now specify the following config parameters:

  - `stack_name`: the name of the benchmark stack (to keep track of the allocated resource in your AWS account).
  - `authorized_ssh_key`: the content of the public ssh key you want to use in case you need to ssh into one of the virtual machines.
  - `token`: the JWT token you want to brute force
  - `alphabet`: the set of characters to use in to generate the strings for the brute force attack
  - `ami`: the AMI id generated in the previous step


### Advanced configuration

You can change more advanced parameters like the type of instance or the number of client processes per instance. If you are curious to experiment with this, you can find the name of the variables in [`benchmark.tf`](/benchmark.tf).


## Run the benchmark

To run the benchmark you have to run:

```bash
terraform init
terraform apply
```

Terraform will show you a preview of all the resources that will be allocated and give you a prompt to confirm that you are OK with it.

Once you confirm, the resources will be allocated and consequently the benchmark will start.


## Monitor execution and results

Once the benchmark is started, you can read the logs in [Cloudwatch](https://eu-west-1.console.aws.amazon.com/cloudwatch) in your AWS account.

You will find a new log group called `JWTCracker`. Inside of if there will be multiple log streams available. Every log stream represents a machine in the brute force cluster.


## Clean up

When you are done, you can clean up everything by running:

```bash
terraform destroy
```


## Contributing

Everyone is very welcome to contribute to this project.
You can contribute just by submitting bugs or suggesting improvements by
[opening an issue on GitHub](https://github.com/lmammino/benchmark-distributed-jwt-cracker/issues).


## License

Licensed under [MIT License](LICENSE). © Luciano Mammino.
