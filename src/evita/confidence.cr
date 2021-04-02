module Evita
  struct Confidence
    getter relevance : Int32
    getter certainty : Int32

    def initialize(@relevance, @certainty)
    end

    def <=>(val : Confidence)
      rel = @relevance
      base_comparison = rel <=> val.relevance

      if base_comparison.zero?
        cert = @certainty
        cert <=> val.certainty
      else
        base_comparison
      end
    end
  end
end
