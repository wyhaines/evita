require "./spec_helper"

describe Evita::Database do
  Spec.before_suite do
    File.delete("./ellie.db") if File.exists?("./ellie.db")
  end
  Spec.after_suite do
    File.delete("./ellie.db") if File.exists?("./ellie.db")
  end

  it "can setup a database for the bot" do
    config = Evita::Config.from_yaml(
      <<-EYAML
      ---
      name: Evita
      database: sqlite3://./ellie.db
      EYAML
    )
    db = Evita::Database.setup(config)
    db.class.should eq DB::Database
  end
end
