# StatusPulse Screenshot Proof

This file is the top-level proof index for the StatusPulse assignment. The full
gallery is available at [screenshots/screenshot.md](screenshots/screenshot.md).

## Proof Summary

| Area | Evidence |
| --- | --- |
| Local Docker stack | [All containers up](<screenshots/All containers up.png>) |
| API health check | [Successful response](<screenshots/successful response.png>) |
| Integration tests | [Tested integrations](<screenshots/tested intergations.png>) |
| Swagger UI | [Swagger UI on local](<screenshots/tested statyspulse - swagger UI on local.png>) |
| Terraform apply | [Terraform deployed](<screenshots/deployed terraform code.png>) |
| EC2 access | [Connected to EC2](<screenshots/connected to ec2.png>) |
| Firewall hardening | [Firewall status](<screenshots/firewall status.png>) |
| TLS certificate | [SSL certificate received](<screenshots/successfully recieved ssl certificate.png>) |
| CI pipeline | [Pipeline build successfully](<screenshots/pipeline build successfully.png>) |
| Deploy pipeline | [Deployment pipeline ran successfully](<screenshots/deployment pipeline runned successfully.png>) |
| CI/CD automation | [Deployment started after CI](<screenshots/deployment started automatically after ci pipeline finished.png>) |
| Uptime Kuma monitoring | [Monitoring dashboard](<screenshots/added monitoring on uptime kuma.png>) |
| Public status page | [Status page services](<screenshots/all service attached on status page.png>) |

## Checklist Covered

- Docker image and running containers
- Local `/health`, Swagger UI, and integration test proof
- Terraform infrastructure provisioning
- EC2 SSH access and firewall status
- TLS certificate bootstrap
- GitHub Actions CI and deployment pipeline
- Uptime Kuma monitors and public status page

## Screenshot Gallery

### Local And Container Proof

![All containers up](<screenshots/All containers up.png>)

![Container running successfully](<screenshots/conatiner running successfully.png>)

![Localhost tested](<screenshots/localhost tested.png>)

![Tested curl](<screenshots/tested curl.png>)

![Tested integrations](<screenshots/tested intergations.png>)

![Swagger UI on local](<screenshots/tested statyspulse - swagger UI on local.png>)

### API Proof

![Successful response](<screenshots/successful response.png>)

![Post incident successful response](<screenshots/post incidentsuccessful response.png>)

### Terraform And EC2 Proof

![Terraform deployed](<screenshots/deployed terraform code.png>)

![Connected to EC2](<screenshots/connected to ec2.png>)

![Firewall status](<screenshots/firewall status.png>)

### TLS And Deployment Proof

![SSL certificate received](<screenshots/successfully recieved ssl certificate.png>)

![Certificate attached](<screenshots/certification attached.png>)

![Pipeline build successfully](<screenshots/pipeline build successfully.png>)

![Deployment pipeline ran successfully](<screenshots/deployment pipeline runned successfully.png>)

![Deployment started automatically after CI pipeline finished](<screenshots/deployment started automatically after ci pipeline finished.png>)

![CI/CD pipelines](<screenshots/pipelines-ci-cd.png>)

### Monitoring Proof

![Added monitoring on Uptime Kuma](<screenshots/added monitoring on uptime kuma.png>)

![All services attached on status page](<screenshots/all service attached on status page.png>)

## Notes

- Screenshots are stored in the `screenshots/` folder.
- Terraform state and local environment files are intentionally not included.
- AWS resources were destroyed after proof capture to avoid unnecessary cost.
