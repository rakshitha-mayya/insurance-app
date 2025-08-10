# AWS EC2 Backstage Template

This repository contains a Backstage Software Template for provisioning AWS EC2 instances using Terraform.

## Template Features

- 🖥️ **Simple EC2 Instance**: t2.micro (free tier eligible)
- 🔒 **Basic Security**: SSH access only
- 📦 **8GB Storage**: Free tier eligible
- 🌐 **Public IP**: Auto-assigned
- 🤖 **GitHub Actions**: Automated deployment
- 📚 **Documentation**: Complete setup guide

## Quick Start

1. **Register Template in Backstage**: Add this repository URL to your Backstage configuration
2. **Set up AWS Credentials**: Configure GitHub secrets for AWS access
3. **Create Instance**: Use Backstage UI to create new EC2 instances

## Template Structure

```
├── template.backstage.yaml     # Main Backstage template definition
└── skeleton/                   # Template files that get copied
    ├── terraform/              # Terraform configuration
    ├── .github/workflows/      # GitHub Actions
    ├── catalog-info.yaml       # Backstage catalog entry
    └── README.md              # Instance documentation
```

## Configuration Required

### In Backstage (app-config.yaml)
```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/YOUR_USERNAME/YOUR_REPO/blob/main/template.backstage.yaml
```

### GitHub Repository Secrets
Required for AWS deployment:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Usage

1. Go to Backstage → Create
2. Find "AWS EC2 Instance" template
3. Fill the form and create
4. GitHub Actions will deploy your EC2 instance automatically

---
*Template created for Backstage Software Catalog*
