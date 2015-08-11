module Parmenides
  module SpecificProcessor
    extend Processor

    module_function

    def process(input)
      input = HistogramProcessor.process(input).dup

      klasses = input.keys.inject([]) { |w, klass| w | klass.ancestors_chain }
      klasses.sort_by!(&:level)
      klasses = klasses.slice_when { |k1, k2| k1.level != k2.level }.to_a

      if klasses.size > 1
        index = 1

        until klasses[index].nil?
          delete = []
          klasses[index].each do |klass|
            super_klass = klass.sub_class_of[0]

            if klasses[index - 1].include?(super_klass)
              input[klass] += input[super_klass]
              delete |= [super_klass]
            end
          end

          delete.each { |klass| input.delete(klass) }

          index += 1
        end
      end

      input
    end
  end
end
