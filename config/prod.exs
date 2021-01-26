use Mix.Config

config :stranger, StrangerWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: "strangerz.herokuapp.com", port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :stranger,
  secret_key: System.get_env("SECRET_KEY_BASE"),
  salt: "user_salt"

# Mongo DB
config :stranger, Mongo,
  name: :mongo,
  pool_size: 2,
  database: "stranger",
  url: System.get_env("MONGO_DB_URL")

# ARC Secrets
config :arc,
  hash_secret: System.get_env("ARC_HASH_SECRET"),
  storage: Arc.Storage.S3,
  bucket: "stranger-prod"

# AWS config for avatar storage in s3
config :ex_aws,
  region: System.get_env("AWS_REGION"),
  access_key_id: System.get_env("AWS_ACCESS_KEY"),
  secret_access_key: System.get_env("AWS_SECRET_KEY")

# Open tok config
config :ex_opentok,
  iss: "project",
  key: System.get_env("OPEN_TOK_API_KEY"),
  secret: System.get_env("OPEN_TOK_SECRET"),
  ttl: 300
