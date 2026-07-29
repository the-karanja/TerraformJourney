# 🚀 Terraform AWS Infrastructure

A minimal, production-conscious Terraform configuration that provisions a public web server on **Amazon EC2**, secured with a scoped **Security Group**, alongside a hardened **S3** bucket and **DynamoDB** table used as a remote backend for Terraform state.

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-eu--north--1-ED7100?logo=amazonaws&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 📐 Architecture

![Architecture Diagram](./assets/architecture-diagram.png)

| Component | Service | Purpose |
|---|---|---|
| 🖥️ Compute | **Amazon EC2** (`t3.micro`) | Runs a lightweight `busybox httpd` web server on port `8080`, bootstrapped via `user_data` |
| 🛡️ Security | **Security Group** | Allows inbound `TCP/8080` from `0.0.0.0/0`; no outbound restrictions applied |
| 🪣 Storage | **Amazon S3** (`tform-bkt-66`) | Versioned, encrypted bucket storing the Terraform remote state file |
| 🔒 Locking | **Amazon DynamoDB** (`tform-locks`) | Pay-per-request table used to acquire state locks and prevent concurrent applies |

---

## 📦 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5`
- An AWS account with credentials configured locally (`aws configure` or environment variables)
- IAM permissions to create EC2 instances, Security Groups, S3 buckets, and DynamoDB tables
- A valid AMI ID for `eu-north-1` (verify the one in `main.tf` is still current before applying)

---

## 📁 Project Structure
├── main.tf # Core resources: EC2, Security Group, S3, DynamoDB
├── backend.tf # S3 remote backend + DynamoDB state locking config
├── .gitignore # Excludes .terraform/, state files, and provider binaries
├── assets/
│ └── architecture-diagram.png
└── README.md

---

## 🧩 Resources Provisioned

| Resource | Name | Notes |
|---|---|---|
| `aws_instance` | `terraform` | `t3.micro`, bootstrapped with `user_data`, replaced on `user_data` change |
| `aws_security_group` | `instance` | Inbound `8080/tcp` open to the internet |
| `aws_s3_bucket` | `terraform-bkt` | `prevent_destroy` lifecycle guard enabled |
| `aws_s3_bucket_versioning` | `enabled` | Versioning set to `Enabled` |
| `aws_s3_bucket_server_side_encryption_configuration` | `default` | `AES256` server-side encryption |
| `aws_s3_bucket_public_access_block` | `public_access` | All four public-access settings blocked |
| `aws_dynamodb_table` | `terraform-locks` | `PAY_PER_REQUEST`, hash key `LockID` |
| `terraform.backend "s3"` | — | Remote state stored in `tform-bkt-66`, locking via `tform-locks`, region `eu-north-1` |

---

## ▶️ Usage

```bash
# 1. Initialize the working directory
terraform init

# 2. Preview the changes
terraform plan

# 3. Apply
terraform apply
```

Once applied, fetch the EC2 instance's public IP and hit port `8080`:

```bash
curl http://<EC2_PUBLIC_IP>:8080
# Hello, World
```

---

## 🔄 Remote Backend

State is stored remotely in S3 with locking via DynamoDB, configured in [`backend.tf`](./backend.tf):

```hcl
terraform {
  backend "s3" {
    bucket         = "tform-bkt-66"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "tform-locks"
    encrypt        = true
  }
}
```

If you're cloning this repo fresh, initialize and migrate any existing local state into the backend:

```bash
terraform init
```

Terraform will prompt to copy existing state into S3 — answer `yes`. From then on, state lives in S3, not on your machine.

> ⚠️ The backend bucket/table must exist **before** this block works. They were bootstrapped in this repo using local state first, then the backend block was added — a common chicken-and-egg pattern when the backend resources are managed by the same Terraform config that uses them.

---

## 🔐 Security Notes

- The Security Group currently opens port `8080` to `0.0.0.0/0` — restrict `cidr_blocks` to a known IP range for anything beyond a demo/lab environment.
- The S3 bucket blocks all public access and enforces `AES256` encryption at rest by default.
- `prevent_destroy = true` on the bucket protects against accidental `terraform destroy` — remove this explicitly if you intend to tear the bucket down.
- `.gitignore` excludes `.terraform/`, `*.tfstate`, `*.tfstate.backup`, and `.terraform.lock.hcl` so provider binaries and local state (which can contain sensitive resource data) never end up in version control.

---

## 🧹 Cleanup

```bash
terraform destroy
```

> The S3 bucket has `prevent_destroy` enabled. Remove or comment out that lifecycle block first if you need to destroy it.

---

