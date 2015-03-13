module Parmenides

	module Evaluation

		class ResourceEvaluator < Evaluator

			def evaluate

				result = Hash.new { |h, k| h[k] = Hash.new }

				base.each do |resource, mappings|

					mappings.each do |lang, mapping|

						coerce = expected.ancestors_chain.include?( mapping ) ||
									mapping.ancestors_chain.include?( expected )

						accuracy = 0.0
						accuracy = expected.level.to_f / mapping.level.to_f if coerce

						eval_result = EvaluationResult.new(
							original: mapping,
							expected: self.expected,
							result: accuracy
							)

						result[resource][lang] = eval_result

					end

				end

				result

			end

			def statistics

				result = evaluate

				lang_stats = Hash.new { |h, k| h[k] = Hash.new( 0 ) }

				result.each_value do |resource|

					resource.each do |lang, eval_result|

						if eval_result.result.nan? || eval_result.result.infinite?
							lang_stats[lang][:new] += 1
						else
							lang_stats[lang][:sum] += eval_result.result
							lang_stats[lang][:count] += 1
						end

					end

				end

				Hash[lang_stats.map do |lang, stat|

					h = { :new => stat[:new],
						  :stat => stat[:sum]/stat[:count] }

					[lang, h]

				end]

			end

		end

	end

end
