# Security

## Container Image

The Dockerfile uses a multi-stage build:

- Builder installs Python dependencies into a virtual environment.
- Runtime uses `python:3.12-alpine`.
- The final container runs as the `statuspulse` non-root user.
- Build caches and package manager indexes are removed from the runtime layer.
- The image includes a Docker `HEALTHCHECK`.

Scan commands:

```bash
docker build -t statuspulse:scan .
trivy image --severity HIGH,CRITICAL statuspulse:scan
```

If vulnerabilities are reported:

```bash
docker pull python:3.12-alpine
docker build --no-cache -t statuspulse:scan .
trivy image --severity HIGH,CRITICAL statuspulse:scan
```

Document the before and after screenshots in `screenshots/`.

## Secret Management

- `.env` and `.env.*` are ignored by Git.
- `.env.example` contains placeholders only.
- Database and Redis passwords are injected at runtime through `.env`.
- GitHub Actions deployment credentials are stored in GitHub Actions secrets.
- Terraform can optionally write `/opt/statuspulse/.env`, but those values are stored in Terraform state. Keep state private or set `write_app_env=false` and create the server `.env` manually.

Useful checks before submitting:

```bash
git status --short
git log -p --all -S "DB_PASSWORD"
git log -p --all -S "REDIS_PASSWORD"
git log -p --all -S "AWS_SECRET_ACCESS_KEY"
```

## Server Hardening

Terraform cloud-init configures:

- Custom SSH port
- `PermitRootLogin no`
- `PasswordAuthentication no`
- Deploy user with Docker permissions
- UFW allowing only custom SSH, HTTP, and HTTPS
- Unattended security upgrades
- Swap for low-memory EC2 instances
- IMDSv2 required on the EC2 instance

## Reverse Proxy

Nginx terminates TLS and adds:

- `Strict-Transport-Security`
- `X-Content-Type-Options`
- `X-Frame-Options`
- `X-XSS-Protection`

Nginx also applies rate limiting:

```nginx
limit_req_zone $binary_remote_addr zone=statuspulse_api:10m rate=100r/m;
limit_req_status 429;
```

Proof commands:

```bash
curl -I https://<your-domain>/
for i in $(seq 1 120); do curl -s -o /dev/null -w "%{http_code}\n" https://<your-domain>/health; done
```
