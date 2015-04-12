require 'thor'
require 'awesome_print'

require 'fileutils'
require 'yaml'

require 'parmenides/CLI/cache_command'

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

				if br.nil?

					# just show the list
					puts "Branches:"
					branches.each do |branch|

						selected_s = " "
						selected_s = "*" if selected_branch == "all" || selected_branch == branch.name

						puts "#{selected_s} #{branch.name}"

					end

				else

					br = br.split( "," ).sort.join( "_" )
					branch_names = branches.map { |b| b.name }

					if options[:new]

						if branch_names.include? br
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

						unless branch_names.include?( br ) || br == "all"
							puts "Can't find such a branch!"
							return
						end

						save_current_branch files.branches.crown, br

					end

				end

			end

			desc "cache SUBCOMMAND ...ARGS", "manage the cache"
			subcommand "cache", CLI::Cache

			no_tasks do

				def save_current_branch path, branch

					File.open( path, "w" ) do |file|
						file.write branch
					end

				end

			end

		end

	end

end
