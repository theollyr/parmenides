module Parmenides

	module Evaluation

		class ResourceBase

			DOMAIN_NAME_RX = Regexp.compile /((?<thld>[^\.]+)\.)?(?<sld>[^\.]+)\.(?<tld>[^\.]+)/

			def self.build based_on:

				resources = based_on
				base = Hash.new { |h, k| h[k] = Hash.new }

				resources.each do |res|

					res.same_as.each do |interlink|

						klass = interlink.type.max_by { |k| k.level }
						lang = interlink.uri.host.match( DOMAIN_NAME_RX )[:thld]

						lang = "en" if lang.nil? || lang == "www"

						base[res][lang] = klass

					end

				end

				new base: base

			end

			def self.load file:, ontology:

				data = YAML.load_file file

				data.each do |res, h|
					h.each do |lang, klass|
						data[res][lang] = ontology.klass klass.split( "/" ).last
					end
				end

				new base: data

			end

			attr_reader :base

			def initialize base:

				@base = base

			end

			def each &blk
				base.each &blk
			end

			def set_custom klass

				base.each_value do |val|
					val[:custom] = klass
				end

			end

			def to_yaml

				Hash[base.map do |res, h|

					h = Hash[h.map { |l, k| [l, k.uri.to_s] }]
					[res.uri.to_s, h]

				end].to_yaml

			end

		end

	end

end
