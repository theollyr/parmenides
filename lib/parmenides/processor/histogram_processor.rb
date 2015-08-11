module Parmenides
  module HistogramProcessor
    extend Processor

    module_function

    def process(input)
      histogram = Hash.new(0)

      input.each do |_, k|
        histogram[k] += 1
      end

      histogram
    end
  end
end
