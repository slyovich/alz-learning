import os

from pymongo import MongoClient
from pymongo.errors import OperationFailure


def create_client_with_connection_string() -> MongoClient:
    connection_string = os.getenv("DOCUMENTDB_CONNECTION_STRING")
    
    if not connection_string:
        raise ValueError(
            "Set DOCUMENTDB_CONNECTION_STRING to your Azure Cosmos DB for MongoDB connection string."
        )

    return MongoClient(
        connection_string,
        connectTimeoutMS=120000,
        tls=True,
        retryWrites=True,
    )


def ensure_user(
    db,
    username: str,
    password: str,
    roles: list[dict[str, str]],
    user_label: str,
) -> None:
    try:
        user_info = db.command("usersInfo", username)
        if user_info.get("users"):
            print(f"{user_label} '{username}' already exists in database 'sampledb'.")
            return

        db.command(
            "createUser",
            username,
            pwd=password,
            roles=roles,
        )
        print(f"Created {user_label} '{username}' in database 'sampledb'.")
    except OperationFailure as error:
        print(f"Failed to create {user_label} '{username}': {error}")


def main() -> None:
    client = create_client_with_connection_string()
    # Verify connection and credentials by pinging the server.
    result = client.admin.command("ping")
    print("Connected successfully:", result)

    # Create a database and collection if they don't exist.
    db = client["sampledb"]
    collection_name = "products"

    if collection_name in db.list_collection_names():
        print(f"Collection '{collection_name}' already exists in database 'sampledb'.")
    else:
        db.create_collection(collection_name)
        print(f"Created collection '{collection_name}' in database 'sampledb'.")

    # Create application and read-only users if they don't exist.
    app_username = os.getenv("SAMPLEDB_APP_USERNAME")
    app_password = os.getenv("SAMPLEDB_APP_PASSWORD")
    readonly_username = os.getenv("SAMPLEDB_READONLY_USERNAME")
    readonly_password = os.getenv("SAMPLEDB_READONLY_PASSWORD")

    if app_username and app_password:
        ensure_user(
            db,
            app_username,
            app_password,
            [
              { "role": "clusterAdmin", "db": "admin" },
              { "role": "readWriteAnyDatabase", "db": "admin" }
            ],
            "application user",
        )
    else:
        print(
            "Skipping application user creation. Set SAMPLEDB_APP_USERNAME and SAMPLEDB_APP_PASSWORD."
        )

    if readonly_username and readonly_password:
        ensure_user(
            db,
            readonly_username,
            readonly_password,
            [
              { "role": "readAnyDatabase", "db": "admin" }
            ],
            "read-only user",
        )
    else:
        print(
            "Skipping read-only user creation. Set SAMPLEDB_READONLY_USERNAME and SAMPLEDB_READONLY_PASSWORD."
        )


if __name__ == "__main__":
    main()