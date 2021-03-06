module Parmenides
  class Infobox

    attr_reader :name
    attr_reader :environment

    include ::Parmenides::Cachable

    caching_by :name
    cache_variable :properties
    cache_variable :resources

    def initialize name:, environment:
      @name = name
      @environment = environment
    end

    def inspect
      "#<%s:%d URI:%s>" % [ self.class.to_s, self.object_id, self.uri ]
    end

    def uri
      @uri ||= environment.main.resource.vocabulary.__send__ "#{environment.main.template}#{name}"
    end

    def resources

      @resources ||= begin

        sk_resources = Hash.new { |h, k| h[k] = Resource.new k }
        int_resources = {}

        environment.client.instance.query( resource_query ).each do |sol|

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
          SELECT ?resource ?sgst ?type
          FROM NAMED #{environment.main.uri.to_base}
        EOQ

        environment.other.uris.each do |uri|
          temp << "FROM NAMED #{uri.to_base}\n"
        end

        temp << <<-EOQ
          WHERE {

            GRAPH #{environment.main.uri.to_base} {

              ?resource #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} .
              ?resource owl:sameAs ?sgst .

        EOQ

        temp << "FILTER( regex( str( ?sgst ), \"http://("

        temp << environment.other.prefixes.map do |prefix|
          Regexp.escape( prefix ).dump[1..-2]
        end.join( "|" )

        temp << ")dbpedia.org\", \"i\" ) ) ."

        temp << <<-EOQ
            }

            VALUES ?g {
        EOQ

        temp << environment.other.uris.map do |uri|
          uri.to_base
        end.join( " " )

        temp << <<-EOQ
            }

            GRAPH ?g {
              ?sgst a ?type .
            }

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

          SELECT ( COUNT( DISTINCT ?resource ) AS ?count ) 
          FROM #{environment.main.uri.to_base}
          WHERE {
            ?resource #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} . 
          }

        EOQ

        # puts count_query
        count = environment.client.instance.query( count_query )[0][:count].to_i

        step = 50
        
        resource_query = <<-EOQ

          SELECT ?res
          FROM #{environment.main.uri.to_base}
          WHERE {{
            SELECT ?res
            FROM #{environment.main.uri.to_base}
            WHERE {
              ?res #{environment.main.property.vocabulary.wikiPageUsesTemplate.to_base} #{uri.to_base} . 
            } ORDER BY ?res 
          }} LIMIT #{step} OFFSET #offset#

        EOQ

        0.step to: count - 1, by: step do |offset|

          print "\rProperties: #{offset} / #{count} (#{(offset / count.to_f * 100).round 2} %)"

          resources = environment.client.instance.query( resource_query.sub( "#offset#", offset.to_s ) )
          resources = resources.map do |sol|
            sol[:res].to_base
          end

          resources = resources.join( " " )

          query = property_query.sub( "#resources#", resources )
          # puts query

          environment.client.instance.query( query ).each do |sol|
            properties[sol[:prop]][sol[:rel]] += 1
          end

        end

        properties

      end

    end

    def property_query

      @property_query ||= begin

        temp = "SELECT ?prop ?rel\n"
        temp << "FROM NAMED #{environment.main.uri.to_base}\n"
        temp << "FROM NAMED #{environment.main.uri_raw.to_base}\n"

        environment.other.uris.each do |uri|
          temp << "FROM NAMED #{uri.to_base}\n"
        end

        filter = "FILTER ( REGEX( STR(#var#), \"http://("

        filter << environment.other.prefixes.map do |prefix|
          Regexp.escape( prefix ).dump[1..-2]
        end.join( "|" )

        filter << ")dbpedia\", \"i\" ) ) ."

        temp << <<-EOQ
          WHERE {

            VALUES ?resource {
              #resources#
            }

            GRAPH #{environment.main.uri_raw.to_base} {
              ?resource ?prop ?ore .
            }

            GRAPH #{environment.main.uri.to_base} {

              ?resource owl:sameAs ?msa .

              #{filter.sub( "#var#", "?msa" )}

            }

            VALUES ?g { 
        EOQ

        temp << environment.other.uris.map do |uri|
          uri.to_base
        end.join( " " )

        temp << <<-EOQ
            }

            OPTIONAL {
              GRAPH #{environment.main.uri.to_base} {
                ?ore owl:sameAs ?osa .
              }

              #{filter.sub( "#var#", "?osa" )}
            }

            GRAPH ?g {

              { ?msa ?rel ?osa . }

              UNION
              
              { ?msa ?rel ?ore . }

            } 

          } 
        EOQ

      end

    end

    def resources_to_cache

      YAML::dump( resources.map do |res|

        ruri = res.uri.to_s
        oths = res.same_as.map do |ore|

          ouri = ore.uri.to_s
          type = ore.type.max_by { |k| k.level }.uri.to_s

          [ ouri, type ]

        end.to_h

        [ ruri, oths ]

      end.to_h )

    end

    def resources_from_cache raw

      @resources = raw.map do |ruri, ores|

        res = Resource.new ruri

        others = ores.each do |ore, type|

          other = Resource.new ore
          other.type << environment.ontology.instance.klass( RDF::URI.new( type ) )

          res.same_as << other

        end

        res

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
