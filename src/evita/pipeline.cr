module Evita
  # A pipeline is just a channel with an extra origin tag that can
  # be used to uniquely identify this particular pipeline.
  class Pipeline(T) < Channel(T)
    property origin : String = Bus.origin_tag
  end
end  