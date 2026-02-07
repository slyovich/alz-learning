# 🚀 Azure Learning Playground

Welcome to your hands-on Azure adventure! This repo is your launchpad for learning Azure using Infrastructure as Code (IaC) with Bicep, Terraform and Azure CLI. Get ready to deploy, break, and rebuild the cloud—one module at a time! ☁️🛠️

---

## 📚 Table of Contents

1. [Introduction](#introduction)
2. [Repository Structure](#repository-structure)
3. [Getting Started](#getting-started)
4. [Modules Overview](#modules-overview)
5. [How to Deploy](#how-to-deploy)
6. [Learning Resources](#learning-resources)
7. [Contributing](#contributing)

---

## 1. 🎉 Introduction

This repository is designed for developers who want to learn Azure by doing! It provides modular Bicep/Terraform/Azure CLI templates to help you bootstrap and manage core Azure resources in a repeatable, automated way. Perfect for experimentation, demos, and cloud mischief. 😈

## 2. 🗂️ Repository Structure

```
0-bootstrap/
  main.bicep                # Main entry point for bootstrapping
  modules/
	 dns-zones.bicep         # DNS zones module
	 lz-vending.bicep        # Landing zone vending module
	 resourcegroups.bicep    # Resource groups module
	 storage.bicep           # Storage accounts module
	 vpngateway.bicep        # VPN gateway module
```

## 3. 🏁 Getting Started

1. **Clone this repo:**
	```sh
	git clone <your-fork-url>
	cd alz-learning
	```
2. **Install [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install):**
	```sh
	az bicep install
	```
3. **Login to Azure:**
	```sh
	az login
	```

## 4. 🧩 Modules Overview

- **dns-zones.bicep**: Manage DNS zones like a boss! 🌐
- **lz-vending.bicep**: Spin up landing zones faster than you can say "cloud"! 🏭
- **resourcegroups.bicep**: Organize your resources (or your life) into groups. 📦
- **storage.bicep**: Store all the things, especially the Terraform state of the next phases! 🗄️
- **vpngateway.bicep**: Secure your cloud traffic with VPNs. 🕵️‍♂️

## 5. 🚦 How to Deploy

Deploy the main bootstrapper:

```sh
az deployment sub create \
  --location <azure-region> \
  --template-file 0-bootstrap/main.bicep
```

You can also deploy individual modules for focused learning.

## 6. 📖 Learning Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Fundamentals](https://learn.microsoft.com/training/paths/azure-fundamentals/)
- [Microsoft Learn](https://learn.microsoft.com/training/)

## 7. 🤝 Contributing

Found a bug, want to add a module, or just want to say hi? Open an issue or PR! Contributions (and memes) are welcome.

---

Happy learning! 🧑‍🚀🌟
