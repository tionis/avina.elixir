import Config
config :nostrum,
  token: System.get_env("DISCORD_TOKEN")

config :avina,
  redis_uri: System.get_env("REDIS_URI"),
  redis_password: System.get_env("REDIS_PASSWORD")
