module Parmenides
  module TrackbackProcessor
    extend Processor

    module_function

    def process(input)
      list = []

      input.each do |prop, maps|
        maps.each do |_, score|
          list << [prop, score]
        end
      end

      list.sort_by! { |elm| -elm.last }
      list.uniq!(&:first)

      used = []
      out = {}

      list.each do |(prop, _)|
        left = input[prop].reject { |rel, _| used.include?(rel) }
        picked = left.max_by { |_, score| score }[0]

        out[prop] = picked
      end

      out
    end
  end
end
