module Parmenides

	class Infobox

		attr_reader :name
		attr_reader :environment

		include ::Parmenides::Cachable

		caching_by :name
		cache_variable :properties

		def initialize name:, environment:

			@name = name

			@environment = environment

		end

		def uri
			@uri ||= environment.main.resource.vocabulary.__send__ "#{environment.main.template}#{name}"
		end

		def resources

			@resources ||= begin

				sk_resources = Hash.new { |h, k| h[k] = Resource.new k }
				int_resources = {}

				environment.client.instance.query( resource_query ).each_solution do |sol|

					skres = sk_resources[sol[:resource]]
					intres = int_resources[sol[:sgst]]

					if intres.nil?

						int_resources[sol[:sgst]] = intres = Resource.new sol[:sgst]
						skres.same_as << intres

					end

					intres.type << ( environment.ontology.instance.klass sol[:type].to_s.split( "/" ).last )

				end

				sk_resources.values

			end

		end

		def resource_query

			@resource_query ||= begin

				temp = <<-EOQ
					SELECT *
					FROM <http://#{environment.main.prefix}dbpedia.org>
				EOQ

				environment.other.prefixes.each do |prefix|
					temp << "FROM <http://#{prefix}dbpedia.org>\n"
				end

				temp << <<-EOQ
					WHERE {

						{
							select * where {

								?resource #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} .
								?resource owl:sameAs ?sgst .
				EOQ

				temp << "FILTER( regex( str( ?sgst ), \"http://("

				en_in = false
				environment.other.languages.each do |lang|
					
					if lang == "en"
						en_in = true
						next
					end

					temp << "#{lang}\\\\.|"

				end

				unless en_in
					temp = temp[0...-1]
				end

				temp << ")dbpedia.org\", \"i\" ) ) ."

				temp << <<-EOQ
							}
						}

						?sgst a ?type .
						FILTER( regex( str(?type), "^http://dbpedia.org/ontology/(?!Wikidata)(.+)$" ) ) .

					}

				EOQ

				temp

			end

		end

		def reload_resources!

			@resources = nil
			resources

		end

		def properties

			@properties ||= begin

				properties = Hash.new { |h, k| h[k] = Hash.new( 0 ) }

				count_query = <<-EOQ

					SELECT ( COUNT( DISTINCT ?resource ) AS ?count ) WHERE {
						?resource #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} . 
					}

				EOQ

				count = environment.client.instance.query( count_query )[0][:count].to_i

				step = 50

				0.step to: count, by: step do |offset|

					query = property_query.sub( "#step#", step.to_s ).sub( "#offset#", offset.to_s )

					environment.client.instance.query( query ).each_solution do |sol|
						properties[sol[:prop]][sol[:rel]] += 1
					end

				end

				properties

			end

		end

		def property_query

			@property_query ||= begin

				temp = "SELECT ?prop ?rel\n"
				temp << "FROM <http://#{environment.main.prefix}dbpedia.org>\n"
				temp << "FROM <http://#{environment.main.language}_raw.dbpedia.org>\n"

				environment.other.prefixes.each do |prefix|
					temp << "FROM NAMED <http://#{prefix}dbpedia.org>\n"
				end

				temp << <<-EOQ
					WHERE {

							{
								SELECT * WHERE {
									?resource #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} . 
								} limit #step# offset #offset#
							}

							?resource ?prop ?ore .
							?resource owl:sameAs ?msa .

							VALUES ?g { 
					EOQ

				environment.other.prefixes.each do |prefix|
					temp << "<http://#{prefix}dbpedia.org> "
				end

				temp << <<-EOQ
							}

							{
								?ore owl:sameAs ?osa .
								GRAPH ?g {
									?msa ?rel ?osa .
								}

							} UNION {

								GRAPH ?g { 
									?msa ?rel ?ore .
								}

							} 

						} 

					EOQ

			end

		end

		def properties_to_cache

			YAML::dump( properties.map do |mprop, others|
				
				others = others.map do |oprop, score|
					[oprop.to_s, score]
				end.to_h

				[mprop.to_s, others]

			end.to_h )

		end

		def properties_from_cache raw

			@properties = raw.map do |mprop, others|

				others = others.map do |oprop, score|
					[RDF::URI.new( oprop ), score]
				end.to_h

				[RDF::URI.new( mprop ), others]

			end.to_h

		end

		def reload_properties!

			@properties = nil
			properties

		end

	end

end
