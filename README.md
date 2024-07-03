# Instructions for migrate.sh script

## Prerequisites

### GitHub

Create a [GitHub PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) with the following permissions:

- Profile in upper right corner
- Developer settings
- Personal access tokens
- Generate new token
- Select the following permissions:
    - admin:org
    - admin:enterprise
    - repo
- Save the token in a secure location

### Local machine
For windows, install [git bash](https://git-scm.com/downloads)

For linux, install git, curl, jq

```bash
sudo apt-get install git curl jq
```

Set github token as an environment variable

```bash
export GITHUB_TOKEN=<your-token>
```

## Clone the repository

```bash
git clone https://github.com/ryano0oceros/organization-backup.git

cd organization-backup
```

## Usage

Save your GitHub token in an environment variable

```bash
export GITHUB_TOKEN=<your-token>
```

## run migrate.sh

```bash
chmod +x migrate.sh
./migrate.sh <org-name> $GITHUB_TOKEN
```

## Optional: Validate contents

Unzip contents, and verify files

## Downstream

```bash
cd <org-name>
cd pack
git verify-pack -v <file-name>.pack
```

## Upload to Azure (incomplete)

```bash
az storage blob upload \
    --account-name <storage-account> \
    --container-name <container> \
    --name myFile.txt \
    --file myFile.txt \
    --auth-mode login
```
