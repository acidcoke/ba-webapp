# Infrastructure-as-Code - Realization of a web application in the public cloud
## Notes
This application can cost up to 1€/h! If it is not used the infrastructure should be destroyed.

## Requirements
To use the application you need:

* The installed [Terraform CLI (1.0.9+)](https://www.terraform.io/downloads)
* The installed [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* An [AWS account](https://console.aws.amazon.com/console/home?nc2=h_ct&src=header-signin)
* Your AWS credentials. You can create a new access key on this [page](https://console.aws.amazon.com/iam/home?#/security_credentials)

Configure the AWS CLI from your terminal. Follow the prompts to enter your AWS Access Key ID and Secret Access Key:
```console
$ aws configure
```

## Using the application
1. Initialize directory:
      ```console
      $ terraform init
      ```

2. Apply config:

      ```console
      $ terraform apply
      ```
      
      ```console
      ...

      Apply complete! Resources: 86 added, 0 changed, 0 destroyed.

      Outputs:

      url = "guestbook.bobcat.s3-website.eu-central-1.amazonaws.com"
      ```
      
      The randomly generated URL in the console output can be used to invoke the application.


3. When the application is no longer needed it can be destroyed:

      ```console
      $ terraform destroy
      ```


## Troubleshooting

If the API responds with http status code 500, destroying and reapplying the configuration may help.
