module Parmenides

	module GenericProcessor
		extend Processor
		extend self

		def process input

			input = HistogramProcessor.process( input ).dup

			klasses = input.keys.inject([]) { |w, klass| w |= klass.ancestors_chain }
			klasses.sort_by! { |k| k.level }
			klasses = klasses.slice_when { |k1, k2| k1.level != k2.level }.to_a

			chosen = nil
			index = 0
			klasses.each_with_index do |subary, i|

				if subary.size == 1
					chosen = subary[0]
				else

					index = i
					break

				end

			end

			klasses[index..-1].each do |subary|

				input[chosen] += subary.inject(0) do |count, k|
					level = k.level
					input.delete k
					count + level
				end

			end

			input

		end

	end

end
