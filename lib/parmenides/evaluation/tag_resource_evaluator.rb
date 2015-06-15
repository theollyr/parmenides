module Parmenides
  module Evaluation
    class TagResourceEvaluator < Evaluator

      def evaluate

        res = Hash.new 0

        questioning.each do |ibx, mapping|

          tresult = 0.0

          cchain = dataset[ibx].ancestors_chain[1..-1] unless dataset[ibx].nil?

          # p cchain

          next if cchain.nil?

          qchain = mapping.ancestors_chain[1..-1]
          # p qchain

          if qchain.size > 0 &&
            [qchain.size, cchain.size].min.times.all? { |i| cchain[i] == qchain[i] }

            if qchain.size >= cchain.size
              tresult = 1.0
            else
              tresult = 1.0 / ( qchain.last.descendants_count( cchain.last.level ) )
            end

          end

          # puts "Infobox <#{ibx}..."
          # puts "Q#{qchain.last} <> C#{cchain.last} :: #{tresult}"

          res[:score] += tresult
          res[:count] += 1

        end

        res

      end

    end
  end
end
