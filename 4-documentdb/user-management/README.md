# User Management (Python)

This project connects to Azure Cosmos DB for MongoDB using native authentication and creates a database, collection, and users with specific roles.

## Prerequisites

- Python 3.10+
- Access to the target Azure Cosmos DB for MongoDB cluster

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## Configuration

Set your cluster name and user credentials as environment variables:

```bash
export DOCUMENTDB_CONNECTION_STRING="<connection-string>"
export SAMPLEDB_APP_USERNAME="<app-username>"
export SAMPLEDB_APP_PASSWORD="<app-password>"
export SAMPLEDB_READONLY_USERNAME="<readonly-username>"
export SAMPLEDB_READONLY_PASSWORD="<readonly-password>"
```

Or load them from the `.env` file.

From the current directory, run:`:

```bash
set -a; source .env; set +a
```

You can verify one variable was loaded with:

```bash
echo "$SAMPLEDB_APP_USERNAME"
```

## Run

```bash
python main.py
```

If authentication and connectivity are successful, the script prints a successful `ping` response.
