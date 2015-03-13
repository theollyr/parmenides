module Parmenides

	module Evaluation

		class PropertyEvaluator < Evaluator

			def evaluate

				results = expected.map do |prop, mapping|

					original = base[prop.to_s]
					expects = mapping
					
					result = if original.nil?
						:missing_base
					elsif expects == original
						:correct
					else
						:wrong
					end

					[prop.to_s, EvaluationResult.new( original: original,
						expected: expects.to_s, result: result )]

				end.to_h

				( base.keys - expected.keys.map( &:to_s ) ).each do |res|

					results[res] = EvaluationResult.new original: base[res],
						expected: nil, result: :missing

				end

				results

			end

			def statistics

				result = evaluate
				stat = Hash.new 0

				result.each_value do |eval_result|

					if eval_result.result == :correct
						stat[:correct] += 1
					elsif eval_result.result == :wrong
						stat[:wrong] += 1
					elsif eval_result.result == :missing_base
						stat[:missing_base] += 1
					elsif eval_result.result == :missing
						stat[:missing] += 1
					end

				end

				stat

			end

		end

	end

end
