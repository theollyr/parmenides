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
			result = client.select.where( 

				[ r_uri, 
				  RDF::RDFS.subClassOf, 
				  :superclass ] 

				).result

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

end
