module Parmenides

	module Evaluation

		class EvaluationResult

			attr_reader :original, :expected, :result

			def initialize original:, expected:, result:

				@original = original
				@expected = expected

				@result = result

			end

		end

	end

end
