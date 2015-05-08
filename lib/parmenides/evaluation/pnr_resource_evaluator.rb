module Parmenides

	module Evaluation

		class PnRResourceEvaluator < Evaluator

			def evaluate

				res = Hash.new 0

				questioning.each do |ibx, mapping|

					cchain = dataset[ibx].ancestors_chain unless dataset[ibx].nil?

					if cchain.nil?
						next
					end

					qchain = mapping.ancestors_chain

					# ap cchain
					# ap qchain

					cchain = cchain[1..-1]
					qchain = qchain[1..-1]

					# ap cchain
					# ap qchain

					qchain.each_with_index do |k, i|

						cmp = cchain[i]

						if cmp.nil?
							res[:fp] += 1
							next
						end

						if k == cmp
							res[:tp] += 1
						else
							res[:fp] += 1
							res[:fn] += 1
						end

					end

					more = cchain.size - qchain.size
					res[:fn] += more if more > 0

				end

				res[:precision] = res[:tp] / ( res[:tp] + res[:fp] ).to_f
				res[:recall] = res[:tp] / ( res[:tp] + res[:fn] ).to_f
				res

			end

		end

	end

end
