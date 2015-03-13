module Parmenides

	class Infobox

		attr_reader :name
		attr_reader :client, :ontology

		def initialize name:, client:, ontology:

			@name = name

			@client = client
			@ontology = ontology

		end

		def uri
			@uri ||= RDF::URI.new "http://sk.dbpedia.org/resource/Šablóna:Infobox_#{name}"
		end

		def resources

			@resources ||= begin

				query = <<-EOQ

					PREFIX skprop: <http://sk.dbpedia.org/property/>
					SELECT *
					FROM <http://sk.dbpedia.org>
					FROM <http://de.dbpedia.org>
					FROM <http://es.dbpedia.org>
					FROM <http://dbpedia.org>
					WHERE {

						{
							select * where {

								?resource skprop:wikiPageUsesTemplate #{uri.to_base} .
								?resource owl:sameAs ?sgst .

								FILTER( regex( str( ?sgst ), "http://(de\\\\.|es\\\\.|)dbpedia.org", "i" ) ) .

							}
						}

						?sgst a ?type .
						FILTER( regex( str(?type), "^http://dbpedia.org/ontology/(?!Wikidata)(.+)$" ) ) .

					}

				EOQ

				sk_resources = Hash.new { |h, k| h[k] = Resource.new k }
				int_resources = {}

				client.query( query ).each_solution do |sol|

					skres = sk_resources[sol[:resource]]
					intres = int_resources[sol[:sgst]]

					if intres.nil?

						int_resources[sol[:sgst]] = intres = Resource.new sol[:sgst]
						skres.same_as << intres

					end

					intres.type << ( ontology.klass sol[:type].to_s.split( "/" ).last )

				end

				sk_resources.values

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

					select ( count( distinct ?resource ) as ?count ) where {
						?resource <http://sk.dbpedia.org/property/wikiPageUsesTemplate> #{uri.to_base} . 
					}

				EOQ

				count = client.query( count_query )[0][:count].to_i

				step = 50

				0.step to: count, by: step do |offset|

					query = <<-EOQ

						select ?prop ?rel
						from <http://sk.dbpedia.org>
						from <http://sk_raw.dbpedia.org>
						from named <http://dbpedia.org>
						from named <http://de.dbpedia.org>
						from named <http://es.dbpedia.org>
						where {

							{
								select * where {
									?resource <http://sk.dbpedia.org/property/wikiPageUsesTemplate> #{uri.to_base} . 
								} limit #{step} offset #{offset}
							}

							?resource ?prop ?ore .
							?resource owl:sameAs ?msa .

							values ?g { <http://dbpedia.org> <http://de.dbpedia.org> <http://es.dbpedia.org>} .

							{
								?ore owl:sameAs ?osa .
								graph ?g {
									?msa ?rel ?osa .
								}

							} union {

								graph ?g { 
									?msa ?rel ?ore .
								}

							} 

						} 

					EOQ

					client.query( query ).each_solution do |sol|
						properties[sol[:prop]][sol[:rel]] += 1
					end

				end

				properties

			end

		end

		def reload_properties!

			@properties = nil
			properties

		end

	end

end
