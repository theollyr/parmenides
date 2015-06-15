module Parmenides
  class Ontology
    class Klass < Entity

      has_property :sub_class_of

      attr_reader :ontology
      attr_accessor :level

      def initialize uri, level:0, **kwargs
        super

        # @ontology = ontology
        @level = level

      end

      def sub_class_of= klass

        sub_class_of.clear
        sub_class_of << klass if klass.is_a? Klass

        # if klass.kind_of? RDF::URI
          
        #   sub_class_of << (self.ontology.klass klass)
        #   self.level = sub_class_of[0].level

        # end

      end

      def ancestors_chain

        @ancestors_chain ||= begin

          current = self
          list = []

          until current.nil?

            list.unshift current
            current = current.sub_class_of[0]

          end

          @ancestors = list

        end

      end

      def == oth
        self.uri == oth.uri
      end

      Thing = self.new ::RDF::OWL.Thing

    end
  end
end
