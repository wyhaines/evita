require "./spec_helper"

describe Evita::CommandLine do
  Spec.before_suite do
    SpecNotes["argv"] = ARGV.to_yaml
  end

  Spec.after_suite do
    ARGV.replace YAML.parse(SpecNotes["argv"]).as_a.map(&.as_s)
  end

  it "can get a version string" do
    ARGV.replace ["test", "-v"]
    config = Evita::CommandLine.parse_options
    config.extra.join.should eq "Evita v#{Evita::VERSION}"

    ARGV.replace ["test", "--version"]
    config = Evita::CommandLine.parse_options
    config.extra.join.should eq "Evita v#{Evita::VERSION}"
  end

  it "can get help" do
    ARGV.replace ["test", "-h"]
    config = Evita::CommandLine.parse_options
    config.extra.join.should match /Usage: evita/

    ARGV.replace ["test", "--help"]
    config = Evita::CommandLine.parse_options
    config.extra.join.should match /Usage: evita/
  end

  it "can explicitly set params" do
    name = "Ellie"
    database = "sqlite3://./ellie.db"
    ARGV.replace ["test", "-n", name, "-d", database]
    config = Evita::CommandLine.parse_options
    config.name.should eq name
    config.database.should eq database
  end

  it "can read config from a file" do
    name = "Ellie"
    database = "sqlite3://./ellie.db"
    ARGV.replace ["test", "-c", "./spec/test_config.yml"]
    config = Evita::CommandLine.parse_options
    config.name.should eq name
    config.database.should eq database
  end
end
