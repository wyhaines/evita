require "./spec_helper"

describe Evita::Handlers::GPT3 do
  it "trims an unfinished, trailing sentence" do
    reply = "Evita: This is one sentence. This is a"
    Evita::Handlers::GPT3.trim_unfinished_sentence(reply)
      .should eq "Evita: This is one sentence."
  end
end
