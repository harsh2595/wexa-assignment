# AWS Terraform

This Terraform creates the AWS side of the StatusPulse deployment:

- Ubuntu EC2 instance
- Security group allowing only custom SSH, HTTP, and HTTPS
- Optional Route 53 `A` records for the app and Uptime Kuma status page
- Cloud-init bootstrap for Docker, Docker Compose, UFW, SSH hardening, unattended upgrades, swap, and cron jobs

AWS public IPv4 and Route 53 can incur small charges depending on your account and region. Destroy the stack when you are done with the assessment.

## Backend

Terraform uses a local backend on your machine:

```hcl
backend "local" {
  path = "state/statuspulse.tfstate"
}
```

The `terraform/state/` directory is kept in the repo with `.gitkeep`, but `*.tfstate` files are ignored because they can contain sensitive infrastructure data.

## Module Layout

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── modules/
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── templates/cloud-init.yaml.tftpl
    └── dns/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

- `networking` discovers the default VPC/subnets and creates the StatusPulse security group.
- `compute` launches the Ubuntu EC2 instance and renders cloud-init server bootstrap.
- `dns` optionally creates Route 53 `A` records when `route53_zone_id` is provided.
- Root `main.tf` wires the modules together and keeps shared project inputs in one place.

## Usage

1. Create an EC2 key pair in AWS.
2. Copy the example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars`:

- Set `key_name` to your EC2 key pair.
- Set `allowed_ssh_cidr` to your public IP with `/32`.
- Set `repository_url` after you push this repo to GitHub.
- Set `domain_name` and `status_domain`.
- Leave `route53_zone_id` empty if you use DuckDNS, Cloudflare, or `sslip.io`.
- Leave `instance_type` empty to auto-select a Free Tier eligible x86_64 instance type in your AWS region.

To see eligible instance types yourself:

```bash
aws ec2 describe-instance-types \
  --region us-east-1 \
  --filters "Name=free-tier-eligible,Values=true" \
  --query "InstanceTypes[].InstanceType" \
  --output table
```

4. Apply:

```bash
terraform init
terraform apply
```

5. SSH to the server using the output:

```bash
ssh -p 2222 deploy@<instance_public_ip>
```

6. If `write_app_env=false`, create `/opt/statuspulse/.env` from `.env.example` on the server and set strong passwords, domain names, and `GHCR_IMAGE`.

7. Bootstrap TLS after DNS points to the EC2 public IP:

```bash
cd /opt/statuspulse
sudo ./scripts/bootstrap-tls.sh
```

8. Deploy:

```bash
cd /opt/statuspulse
sudo APP_IMAGE=ghcr.io/YOUR_USERNAME/statuspulse:latest ./scripts/deploy.sh
```

## Destroy

```bash
terraform destroy
```
