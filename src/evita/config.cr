# Database : String
# Name : String

module Evita
  class Config
    include YAML::Serializable
    include YAML::Serializable::Unmapped

    # This is the name of the bot. If unspecified, it's name is Evita.
    @[YAML::Field(key: "name")]
    property name : String = "Evita"

    # The bot will maintain a database for use by the handlers.
    # The default is a SQLite database local to where the bot is
    # being executed.
    @[YAML::Field(key: "database")]
    property database : String = "sqlite3://./evita.db"

    property mode : String = "test"
  end
end
