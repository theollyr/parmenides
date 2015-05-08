module Parmenides

	module Evaluation

		class PropertyEvaluator < Evaluator

			def evaluate

				questioning.map do |ibx, mappings|

					expected_mappings = dataset[ibx]

					map_result = if expected_mappings.nil?
						:missing_dataset
					else

						part = mappings.map do |property, mapping|

							expected = expected_mappings[property]

							result = if expected.nil?
								:missing
							elsif mapping == expected
								:correct
							else
								:wrong
							end

							temp = {}
							temp[:property] = property
							temp[:mapping] = mapping
							temp[:result] = result

							temp

						end

						# part |= ( expected_mappings.keys - mappings.keys ).map do |mapping|

						# 	temp = {}
						# 	temp[:mapping] = mapping
						# 	temp[:result] = :unknown

						# end

						part

					end

					[ibx, map_result]

				end.to_h

			end

			def statistics

				result = evaluate
				stat = Hash.new { |h, k| h[k] = [] }

				result.each_value do |eval_result|
					stat[eval_result.result] << eval_result
				end

				stat

			end

		end

	end

end
