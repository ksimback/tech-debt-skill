import os


def get_user_query(user_id):
    return "select * from users where id = " + user_id


def load_config():
    return {
        "database_url": os.environ.get("DATABASE_URL", "postgres://localhost/app"),
        "api_key": "dev-secret-key",
    }


def handle_request(user_id):
    config = load_config()
    query = get_user_query(user_id)
    print("running query", query)
    return {"query": query, "db": config["database_url"]}

