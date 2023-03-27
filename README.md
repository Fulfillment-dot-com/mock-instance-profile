# Mock EC2 instance metadata endpoint using docker-compose

Based on [**slimm609/mock-instance-profile**](https://github.com/slimm609/mock-instance-profile) and information from [amazon-ec2-metadata-mock](https://github.com/aws/amazon-ec2-metadata-mock/issues/184)

Using this you can generate a minimal alpine container to act as an ec2 metadata mock server that will serve real credentials based on a given role. The container can then be used in a `docker-compose` stack to act as the ec2 metadata server for any container you setup a custom network on.

# Prerequisites

## Create an IAM Role

This will be a [role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) used as [an ec2 instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)

### Specify a prinicpal for a trusted relationship

Edit the role (or while you are creating it) specify a [**trusted relationship**](https://aws.amazon.com/blogs/security/how-to-use-trust-policies-with-iam-roles/) for a [principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html) (usually your IAM account).

An example on the role `my-example-ec2-role`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com",
                "AWS": "arn:aws:iam::MY_AWS_ACCOUNT:user/MY_IAM_USER"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### Give the prinicpal `AssumeRole`

Can add as a permission directly or create a new policy.

Create a permission/policy that gives [`Assumerole`](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html) for the same IAM account/principal you specified in the above step. You will specify the name of the **Role** you created above. Attach the policy to your account.

Example:

```json
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::MY_AWS_ACCOUNT:role/my-example-ec2-role"
    }
}
```

# Docker-Compose Setup

You will need two supply two pieces of information:

* **Role ARN* -- The ARN for the **Role** you [previously created](#create-an-iam-role)
* A method of supplying credentials to the ec2-metadata container through the [default credential chain](https://github.com/slimm609/mock-instance-profile#local-metadata-mock) in order for the mock service to generate useable credentials.
  * The example below assumes you will use an IAM account key/secret passed through env

```yaml
version: '3.7'

services:
  app:
    image: MY_APP_IMAGE
    networks:
      credentials_network:
        ipv4_address: "169.254.169.2"
      default:

  ec2Meta:
    image: ec2-meta-test
    build: 'https://github.com/Fulfillment-dot-com/mock-instance-profile.git'
    networks:
      credentials_network:
        # Special IP address is recognized by the AWS SDKs and AWS CLI
        ipv4_address: "169.254.169.254"
    environment:
      # The role ARN to generate credentials for
      PROFILE_ARN: "arn:aws:iam::MY_AWS_ACCOUNT:role/my-example-ec2-role"
      # Your IAM Account key
      AWS_ACCESS_KEY_ID: MY_KEY
      # Your IAM account secret
      AWS_SECRET_ACCESS_KEY: MY_SECRET

networks:
  default:
    name: myDefaultNetwork
  credentials_network:
    driver: bridge
    ipam:
      config:
        - subnet: "169.254.169.0/24"
          gateway: 169.254.169.1

```