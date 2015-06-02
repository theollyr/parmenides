require 'thor'
require 'awesome_print'

require 'fileutils'
require 'yaml'

require 'nokogiri'

require 'parmenides/CLI/cache_command'
require 'parmenides/CLI/leaf_command'

require 'parmenides/CLI/root_path'
require 'parmenides/CLI/tree_dir'
require 'parmenides/CLI/branch_dir'

require 'parmenides/CLI/branch'

module Parmenides

	module CLI

		class ParmenidesCLI < Thor

			class_option :dir, aliases: '-d', type: :string, default: "."

			desc "roots", "roots a new tree"
			option :client, aliases: '-c', type: :string, required: true
			option :language, aliases: '-l', type: :string, required: true
			option :template, aliases: '-t', type: :string, required: true
			def roots

				files = TreeDir.new options[:dir]

				settings = { 
					:main => { :language => options[:language],
							   :template => options[:template] },
					:client => { :uri => options[:client] }
				}

				File.open( files.settings, "w" ) { |file|  
					file.write settings.to_yaml
				}

				Dir.mkdir files.truth.root
				Dir.mkdir files.branches.root

				FileUtils.touch files.tree
				FileUtils.touch files.branches.crown

			end

			desc "branch [BRANCH]", "selects BRANCH as the working one"
			option :new, aliases: '-n', type: :boolean
			def branch br = nil

				files = TreeDir.new options[:dir]

				selected_branch = File.read( files.branches.crown ).chomp
				branches = Branch.scan_dir files.branches.root

				unless selected_branch == "all"
					selected_branch = selected_branch.split("*")
				end

				if br.nil?

					# just show the list
					puts "Branches:"
					branches.each do |branch|

						selected_s = " "
						selected_s = "*" if selected_branch == "all" || selected_branch.include?( branch.name )

						puts "#{selected_s} #{branch.name}"

					end

				else

					br = br.split( "-" ).map { |b| b.split(",").sort.join( "_" ) }
					branch_names = branches.map { |b| b.name }

					if options[:new]

						if br.size > 1
							puts "Can't create more than one brach at once!"
							return
						end

						if branch_names.include? br[0]
							puts "Can't create already existing branch!"
							return
						end

						branch = Branch.new br
						branch.root = File.join files.branches.root, br

						branch.save!

						if branches.empty?
							save_current_branch files.branches.crown, br
						end

					else

						unless ( br & branch_names ) == br || br == ["all"]
							puts "Can't find such a branch!"
							return
						end

						save_current_branch files.branches.crown, br.join("*")

					end

				end

			end

			desc "autumn", "create new set of mapping results"
			option :property_mapper, aliases: '-p', type: :string
			option :resource_mapper, aliases: '-r', type: :string
			option :leaf, aliases: '-f',type: :array
			option :simulate, aliases: '-s', type: :boolean
			option :label, aliases: '-l', type: :string
			def autumn

				files = TreeDir.new options[:dir]
				branches = get_branches files

				prop_map = ::Parmenides::Mappers.const_get options[:property_mapper] if options[:property_mapper]
				res_map = ::Parmenides::Mappers.const_get options[:resource_mapper] if options[:resource_mapper]

				conf = ::Parmenides::Environment.empty
				conf.configure_from_hash Psych.load_file( files.settings )

				branches.each do |branch|

					conf.cache.directory = branch.root.cache.root
					conf.other.languages = branch.name.split( "_" )

					leaves = if options[:leaf]
						options[:leaf]
					else
						branch.leaves
					end

					properties = {}
					resources = {}

					leaves.each do |leaf|

						ibx = ::Parmenides::Infobox.new name: leaf, environment: conf
						ibx.load_cache

						unless prop_map.nil?

							res = prop_map.mapping_for ibx.properties

							properties[ibx.uri.to_s] = res.map do |prop, pred|
								[prop.to_s, pred.to_s]
							end.to_h

						end

						unless res_map.nil?

							res = res_map.mapping_for ibx.resources
							res = res.uri.to_s unless res.nil?

							resources[ibx.uri.to_s] = res

						end

					end

					unless options[:simulate]

						branch.season += 1
						branch.save!

						season_file = branch.root.seasons.root
						season_file = File.join season_file, "#{branch.season.to_s}_#{options[:label]}"

						Dir.mkdir season_file

						unless properties.empty?

							File.open( File.join( season_file, "properties.yaml" ), "w" ) do |file|
								file.write properties.to_yaml
							end

						end

						unless resources.empty?

							File.open( File.join( season_file, "resources.yaml" ), "w" ) do |file|
								file.write resources.to_yaml
							end

						end

					else

						puts "Branch #{branch.name}..."
						ap properties unless properties.empty?
						ap resources unless resources.empty?

					end

				end

			end

			desc "evaluate", "evaluates the season against the Truth"
			# option :show_missing, aliases: '-m', type: :boolean
			option :only_resources, aliases: '-r', type: :boolean
			option :only_properties, aliases: '-p', type: :boolean
			option :method, aliases: '-m', type: :string, default: 'pnr'
			option :label, aliases: '-l', type: :string
			def evaluate

				files = TreeDir.new options[:dir]

				conf = ::Parmenides::Environment.empty
				conf.configure_from_hash Psych.load_file( files.settings )

				if options[:method] == "hierarchy"
					puts "Loading ontology..."
					conf.ontology.instance = Parmenides::StaticOntology.new client: conf.client.instance
				end

				get_branches( files ).each do |branch|

					puts
					puts "Branch #{branch.name}..."

					if options[:only_resources]

						truth_res_file = files.truth.resources
							
						quest_res_file = get_season_file options[:label], branch, "resources.yaml"
						next if quest_res_file.nil?

						if File.exists?( truth_res_file ) && File.exists?( quest_res_file )

							questioning = Psych.load_file quest_res_file
							truth = Psych.load_file truth_res_file

							evaluator = unless options[:method] == "hierarchy"

								questioning = questioning.map do |uri, klass|
									k = if klass.nil? 
										::Parmenides::Ontology::Klass::Thing 
									else
										conf.ontology.instance.klass( klass.split( "/" ).last )
									end

									[uri, k]
								end.to_h

								truth = truth.map do |uri, klass|
									[uri, conf.ontology.instance.klass( klass.split( "/" ).last )]
								end.to_h

							# ap questioning
							# ap truth

								::Parmenides::Evaluation::PnRResourceEvaluator.new questioning: questioning, dataset: truth

							else

								questioning = questioning.map do |uri, klass|

									k = conf.ontology.instance.klass ::RDF::URI.new klass
									[uri, k]

								end.to_h

								truth = truth.map do |uri, klass|

									k = conf.ontology.instance.klass ::RDF::URI.new klass
									[uri, k]

								end.to_h

								::Parmenides::Evaluation::TagResourceEvaluator.new questioning: questioning, dataset: truth

							end

							puts
							puts "Resources:"

							ap evaluator.evaluate

						end

					end

					if options[:only_properties]

						truth_prop_file = files.truth.properties
						quest_prop_file = get_season_file options[:label], branch, "properties.yaml"
						next if quest_prop_file.nil?

						stat = Hash.new 0

						if File.exists?( truth_prop_file ) && File.exists?( quest_prop_file )

							questioning = Psych.load_file quest_prop_file
							truth = Psych.load_file truth_prop_file

							evaluator = ::Parmenides::Evaluation::PropertyEvaluator.new questioning: questioning, dataset: truth

							puts
							puts "Properties:"
							eval_res = evaluator.evaluate

							eval_res.each do |ibx, results|

								puts
								puts "Infobox: #{ibx}:"

								results.each do |res|

									stat[res[:result]] += 1

									unless res[:result] == :missing && !options[:show_missing]
										puts "[#{res[:result]}] #{res[:property]} -> #{res[:mapping]}"
									end

								end

							end

						end

						ap stat

					end

				end

			end

			desc "mappers", "lists all available mappers"
			def mappers

				puts "Available mappers:"
				::Parmenides::Mappers.constants( false ).each do |k|
					puts "  #{k}" unless k == :Mapper
				end

			end

			desc "export", "exports mappings to DBpedia format"
			option :season, aliases: '-s', type: :string
			option :xml, aliases: '-x', type: :boolean
			def export

				files = TreeDir.new options[:dir]

				conf = ::Parmenides::Environment.empty
				conf.configure_from_hash Psych.load_file( files.settings )

				get_branches( files ).each do |branch|

					puts
					puts "Branch #{branch.name}..."

					path = get_season_file options[:season], branch, ""
					next if path.nil?

					resources = File.join path, "resources.yaml"
					properties = File.join path, "properties.yaml"

					if File.exists?( resources ) && File.exists?( properties )

						resources = Psych.load_file resources
						properties = Psych.load_file properties

						if options[:xml]

							xmlo = Nokogiri::XML::Builder.new encoding: 'utf-8' do |x|
								x.mediawiki xmlns: "http://www.mediawiki.org/xml/export-0.8/" do

									resources.each do |ibx, klass|

										x.page do

											ibx.match conf.main.template
											ibx_name = $'
											x.title "Mapping #{conf.mail.language}:#{ibx_name}"

											x.revision do 

												outmap = <<-EOM
{{TemplateMapping\n| mapToClass = #{klass.split("ontology/").last}
| mappings =
												EOM

												properties[ibx].each do |atr, pred|

													outmap << <<-EOM
  {{ PropertyMapping | templateProperty = #{atr.split("property/").last}" | ontologyProperty = #{pred.split("ontology/").last} }}"
													EOM

												end

												outmap << "}}"

												x.text outmap

											end

										end

									end

								end
							end

							puts xmlo.to_xml

						else

							resources.each do |ibx, klass|

								outmap = <<-EOM
{{TemplateMapping\n| mapToClass = #{klass.split("ontology/").last}
| mappings =
								EOM

								properties[ibx].each do |atr, pred|

									outmap << <<-EOM
  {{ PropertyMapping | templateProperty = #{atr.split("property/").last}" | ontologyProperty = #{pred.split("ontology/").last} }}"
									EOM

								end

								outmap << "}}"

								puts "Mapping for the infobox #{ibx}..."
								puts "----"

								puts "#{outmap}\n---"

							end

						end

					end

				end

			end

			desc "cache SUBCOMMAND ...ARGS", "manage the cache"
			subcommand "cache", CLI::Cache

			desc "leaf SUBCOMMAND ...ARGS", "manage the leaves (infoboxes) of the current branch"
			subcommand "leaf", CLI::Leaf

			no_tasks do

				def save_current_branch path, branch

					File.open( path, "w" ) do |file|
						file.write branch
					end

				end

				def get_branches files

					selected_branch = File.read( files.branches.crown ).chomp

					if selected_branch == "all"
						CLI::Branch.scan_dir files.branches.root
					else

						selected_branch.split("*").map do |b|

							branch = CLI::Branch.new b
							branch.load File.join( files.branches.root, b )

							branch

						end

					end

				end

				def get_season_file label, branch, filename

					if label.nil?
						File.join branch.root.seasons.root, branch.season.to_s, filename
					else

						if /\A\d+\z/.match(label)

							spath = File.join( branch.root.seasons.root, "#{label}*#{File::Separator}" )
							search = Dir.glob( spath )
							return nil if search.empty?

							File.join search.first, filename

						else

							spath = File.join( branch.root.seasons.root, "*#{label}#{File::Separator}" )
							search = Dir.glob( spath )
							return nil if search.empty?

							File.join search.first, filename

						end

					end

				end

			end

		end

	end

end
