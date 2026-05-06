# AWS Terraform

This Terraform creates the AWS side of the StatusPulse deployment:

- Ubuntu EC2 instance
- Security group allowing only custom SSH, HTTP, and HTTPS
- Optional Route 53 `A` records for the app and Uptime Kuma status page
- Cloud-init bootstrap for Docker, Docker Compose, UFW, SSH hardening, unattended upgrades, swap, and cron jobs

AWS public IPv4 and Route 53 can incur small charges depending on your account and region. Destroy the stack when you are done with the assessment.

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
