module Parmenides
  module MergePreprocessor
    extend Processor

    module_function

    def process(input)
      suggestions = {}

      input.each do |resource|
        # picks all possible klasses for this resource
        # based on what type the interlinks are
        klasses = resource.same_as.inject([]) do |set, oth|
          # take only the class of the highest level
          # since they all are in one hierarchy
          set | [oth.type.max_by(&:level)]
        end

        # replace top class with the whole hierarchy chain
        klasses.map!(&:ancestors_chain)

        hierarchies = []

        # zip up the klasses on each level
        klasses.each do |k|
          hierarchies = zip_max(k, hierarchies)
        end

        # remove nils from, and make uniq, each level
        hierarchies.map! { |h| h.compact.uniq }

        suggestion = nil

        # the last level that contains only one klass is
        # the most specific klass possible to find
        hierarchies.each do |h|
          if h.size == 1
            suggestion = h[0]
          else
            break
          end
        end

        suggestions[resource] = suggestion
      end

      suggestions
    end

    def zip_max(a, b)
      size = a.size
      size = b.size if b.size > size

      out = []
      size.times do |i|
        ary = []

        c = a[i]
        d = b[i]

        if c.is_a?(Array)
          ary.concat(c)
        else
          ary << c
        end

        if d.is_a?(Array)
          ary.concat(d)
        else
          ary << d
        end

        out[i] = ary
      end

      out
    end
    private :zip_max
  end
end
