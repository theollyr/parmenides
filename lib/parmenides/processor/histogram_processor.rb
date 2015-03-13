module Parmenides

	module HistogramProcessor
		extend Processor
		extend self

		def process input

			histogram = Hash.new 0

			input.each do |r, k|
				histogram[k] += 1
			end

			histogram

		end

	end

end
