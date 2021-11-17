import Config
config :nostrum,
  num_shards: :auto,
  gateway_intents: :all
  #  :guilds,
  #  :guild_presences*,
  #  :guild_messages,
  #  :guild_members*,
  #  :direct_messages,
  #  :direct_message_reactions
  #]

config :logger,
  level: :warn
