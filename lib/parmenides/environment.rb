module Parmenides

	module Environment

		class << self

			def from_hash hash

				env = ::Configatron::RootStore.new
				env.configure_from_hash hash

				env.client.uri = ::RDF::URI.new env.client.uri

				env.client.instance = ::SPARQL::Client.new env.client.uri

				env.main.prefix = prefixate env.main.language
				env.main.language = "" if env.main.language == "en"

				env.other.prefixes = env.other.languages.map do |lang|
					prefixate lang
				end

				env.main.resource.uri = ::RDF::URI.new "http://#{env.main.prefix}dbpedia.org/resource/"
				env.main.resource.vocabulary = ::RDF::Vocabulary.new env.main.resource.uri

				env.main.property.uri = ::RDF::URI.new "http://#{env.main.prefix}dbpedia.org/property/"
				env.main.property.vocabulary = ::RDF::Vocabulary.new env.main.property.uri

				env.ontology.instance = ::Parmenides::Ontology.new client: env.client.instance

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

			def prefixate lang
				if lang == "en"
					""
				else
					lang + "."
				end
			end
			private :prefixate

		end

	end

end



