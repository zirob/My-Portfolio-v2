# My Portfolio v2

A static personal portfolio hosted on AWS using Amazon S3 and Amazon CloudFront. Terraform manages the infrastructure and uploads the website files.

## Live website

[Visit my portfolio](https://d32v6zvm6hr436.cloudfront.net)

## Architecture

- **Amazon S3** stores the static website files in a private bucket.
- **Amazon CloudFront** delivers the website over HTTPS.
- **CloudFront Origin Access Control (OAC)** lets CloudFront access the private S3 bucket.
- **An S3 bucket policy** grants read access to this CloudFront distribution only.
- **Terraform** provisions the AWS resources and uploads the site files.

```text
Visitor → CloudFront → Private S3 bucket
```

## Repository Structure

```text
.
├── main.tf
├── outputs.tf
├── terraform.tf
└── website/
    ├── index.html
    ├── css/
    │   └── styles.css
    ├── js/
    │   └── script.js
    └── img/
        ├── favicon.svg
        └── Photo_of_Portfolio.webp
```

## Prerrequisites

- Terraform CLI
- AWS CLI configured with credentials that can manage S3 and CloudFront resources
- An AWS account
Terraform uses the AWS credentials available in your local AWS configuration. Do not put access keys or secret keys in the Terraform files or commit them to Git.

