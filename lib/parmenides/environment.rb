module Parmenides

	module Environment

		class << self

			def empty

				env = ::Configatron::RootStore.new
				env.client.instance = ::Configatron::Delayed.new {
					::Parmenides::Client.new env.client.uri
				}

				env.ontology.instance = ::Configatron::Delayed.new {
					::Parmenides::Ontology.new client: env.client.instance
				}

				env.main.prefix = ::Configatron::Delayed.new do

					if env.main.language != "en"
						env.main.language + "."
					else
						""
					end

				end

				env.main.uri = ::Configatron::Delayed.new { 
					::RDF::URI.new "http://#{env.main.prefix}dbpedia.org"
				}

				env.main.uri_raw = ::Configatron::Delayed.new do

					prefix = ""
					prefix = "#{env.main.language}_" unless env.main.language == "en"

					::RDF::URI.new "http://#{prefix}raw.dbpedia.org"

				end

				env.other.prefixes = ::Configatron::Dynamic.new do

					env.other.languages.map do |lang|

						if lang != "en"
							lang + "."
						else
							""
						end

					end

				end

				env.other.uris = ::Configatron::Dynamic.new do
					
					env.other.languages.map do |lang|

						prefix = ""
						prefix = "#{lang}." unless lang == "en"

						::RDF::URI.new "http://#{prefix}dbpedia.org"

					end

				end

				env.main.resource.vocabulary = ::Configatron::Delayed.new {
					::RDF::Vocabulary.new "http://#{env.main.prefix}dbpedia.org/resource/"
				}

				env.main.property.vocabulary = ::Configatron::Delayed.new {
					::RDF::Vocabulary.new "http://#{env.main.prefix}dbpedia.org/property/"
				}

				env

			end

			def from_hash hash

				env = empty
				env.configure_from_hash hash

				env.client.uri = ::RDF::URI.new env.client.uri

				if env.has_key? :cache
					env.cache.directory = File.expand_path env.cache.directory
				end

				env.lock!

				env

			end

			def from_parameters client:, main_language:, other_languages:, template:, cache_dir:nil

				h = {
					:main => { :language => main_language,
							   :template => template },
					:other => { :languages => other_languages },
					:client => { :uri => client }
				}

				if cache_dir
					h[:cache] = {}
					h[:cache][:directory] = cache_dir
				end

				self.from_hash h

			end

		end

	end

end



