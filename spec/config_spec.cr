require "./spec_helper"

describe Evita::Config do
  it "can parse a YAML config" do
    config = Evita::Config.from_yaml(
      <<-EYAML
      ---
      name: Evita
      database: sqlite3://./evita.db
      EYAML
    )

    config.name.should eq "Evita"
    config.database.should eq "sqlite3://./evita.db"
  end
end
