module Parmenides

	class Ontology

		attr_reader :client
		attr_reader :vocabulary

		def initialize client:

			@vocabulary = ::RDF::Vocabulary.new "http://dbpedia.org/ontology/"

			@client = client

			@resource_cache = {}
			@property_cache = {}

		end

		def klass label

			if label.is_a? ::RDF::URI
				label = label.to_s.split( "/" ).last
			end

			@resource_cache[label.to_sym] ||= build_resource label 

		end

		def property label
			@property_cache[label.to_sym] ||= build_property label
		end

		def build_resource label

			if label.is_a? RDF::URI
				r_uri = label
			else
				r_uri = vocabulary.__send__( label )
			end

			# get subClassOf
			result = client.query( <<-EOQ

				SELECT ?superclass
				FROM <http://dbpo.dbpedia.org>
				WHERE {

					#{r_uri.to_base} rdfs:subClassOf ?superclass .
					FILTER( REGEX( STR( ?superclass ), "http://dbpedia.org/ontology/", "i" ) ) .

				}

				EOQ
			)

			if result.size == 1
				
				resource = Klass.new r_uri, ontology: self

				resource.sub_class_of = klass result.first[:superclass].to_s.split( "/" ).last
				resource.level = resource.sub_class_of[0].level + 1

				resource

			else
				Klass::Thing
			end

		end

		def build_property label
			Property.new vocabulary.__send__( label )
		end

	end


	class StaticOntology

		class Klass

			attr_accessor :sub_class_of, :super_class_of
			attr_reader :uri

			def initialize uri

				@uri = uri
				@sub_class_of = nil
				@super_class_of = []

			end

			def inspect
				"#<#{self.class}:#{self.object_id} #{uri.to_s.split("/").last}>"
			end

			alias_method :to_s, :inspect

			def descendants_count limit_level=nil

				if !limit_level.nil? && level > limit_level
					return 0
				end

				super_class_of.inject(1) do |sum, k|
					sum + k.descendants_count( limit_level )
				end

			end

			def level
				@level ||= ancestors_chain.size - 1
			end

			def ancestors_chain

				@ancestors_chain ||= begin

					current = self
					list = []

					until current.nil?

						list.unshift current
						current = current.sub_class_of

					end

					@ancestors = list

				end

			end

		end

		attr_reader :client

		def initialize client:

			@client = client
			@klasses = {}

			load_klasses

		end

		def load_klasses

			query = <<-EOQ

				SELECT *
				FROM <http://dbpo.dbpedia.org>
				WHERE {

					?child rdfs:subClassOf ?parent .

				}
			EOQ

			results = client.query query

			results.each do |result|

				if result.all? { |k, v| ::RDF::OWL.Thing == v || v =~ /^http:\/\/dbpedia.org\/ontology/ }

					child = klass result[:child]
					parent = klass result[:parent]

					child.sub_class_of = parent if child.sub_class_of.nil?
					parent.super_class_of << child

				end

			end

		end

		def klass uri

			return @klasses[uri] unless @klasses[uri].nil?

			@klasses[uri] = StaticOntology::Klass.new uri

		end

		def dump root

			subclasses = root.super_class_of.map { |sk| dump sk }
			{ root.uri.to_s => subclasses }

		end

	end

end
