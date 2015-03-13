require 'thor'
require 'awesome_print'

module Parmenides

	module CLI

		class ParmenidesCLI < Thor

			desc "map WHAT", "creates WHAT (class or properties) mapping for infobox"
			option :infobox, type: :array
			option :mapper, type: :string
			def map what

				case what
				when "class"

					mapper = Parmenides::Mappers.const_get options[:mapper]

					options[:infobox].each do |ibx_name|

						ibx = Parmenides::Infobox.new name: ibx_name, 
							ontology: Parmenides::DBpOntology,
							client: Parmenides::Client

						puts ibx_name + ": " + mapper.mapping_for( ibx.resources ).uri

					end

				when "properties"

					mapper = Parmenides::Mappers::BasicPropertyMapper

					options[:infobox].each do |ibx_name|

						ibx = Parmenides::Infobox.new name: ibx_name,
							ontology: Parmenides::DBpOntology,
							client: Parmenides::Client

						puts "Infobox #{options[:infobox]}..."
						ap( ( mapper.mapping_for( ibx.properties ).map { |r, m| [r.to_s, m.to_s] }.to_h ),
							indent: -2 )

					end

				end

			end

			desc "evaluate WHAT", "evaluates the result of a mapping for WHAT"
			option :infobox, type: :array
			option :mapper, type: :array
			option :with, type: :string
			def evaluate what

				case what
				when "class"

					mappers = options[:mapper].map { |n| Parmenides::Mappers.const_get n }
					base = Parmenides::Evaluation::ResourceBase.load file: options[:with], ontology: Parmenides::DBpOntology

					options[:infobox].each do |ibx_name|

						ibx = Parmenides::Infobox.new name: ibx_name,
							ontology: Parmenides::DBpOntology,
							client: Parmenides::Client

						mappers.each do |mapper|

							expect = mapper.mapping_for ibx.resources

							ev = Parmenides::Evaluation::ResourceEvaluator.new expected: expect, base: base

							puts "Class mapping for infobox #{options[:infobox]} with #{mapper}..."
							ap ev.statistics

						end

					end

				when "properties"

					mapper = Parmenides::Mappers::BasicPropertyMapper
					base = YAML.load_file options[:with]

					ibx = Parmenides::Infobox.new name: options[:infobox][0],
						ontology: Parmenides::DBpOntology,
						client: Parmenides::Client

					expect = mapper.mapping_for ibx.properties

					ev = Parmenides::Evaluation::PropertyEvaluator.new expected: expect, base: base

					ap ev.statistics

				end

			end

		end

	end

end
