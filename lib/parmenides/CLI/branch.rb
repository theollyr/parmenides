module Parmenides

	module CLI

		class Branch

			def self.scan_dir path

				path = File.join path, "*"
				path = File.join path, ".branch"

				Dir[path].map do |file|

					dir = File.dirname file

					branch = new File.basename( dir )
					branch.load dir

					branch

				end

			end

			attr_accessor :season

			attr_reader :name
			attr_reader :leaves

			def initialize name

				@name = name
				@season = 0
				@physical = false

				@leaves = []

			end

			def root= nroot

				if nroot.is_a? CLI::BranchDir
					@root = nroot
				# elsif nroot.is_a? CLI::TreeDir
					# @root = CLI::BranchDir.new File.join( nroot.branches.root, name )
				else
					@root = CLI::BranchDir.new nroot # File.join( nroot, name )
				end

			end
			attr_reader :root

			def physical?
				@physical
			end

			def add_leaf leaf
				@leaves |= [ leaf ]
			end

			def remove_leaf leaf
				@leaves -= [ leaf ]
			end

			def save!

				unless root
					raise "missing root directory"
				end

				unless physical?

					Dir.mkdir root.root

					Dir.mkdir root.cache.root
					Dir.mkdir root.seasons.root

					@physical = true

				end

				File.open root.branch, "w" do |file|

					data = {
						:current_season => season,
						:leaves => leaves
					}

					file.write data.to_yaml

				end

			end

			def load troot=nil

				if troot
					self.root = troot
				end

				if root

					data = Psych.load_file root.branch

					@season = data[:current_season]
					@leaves = data[:leaves]

				else
					raise "missing root directory"
				end

				@physical = true

			end

		end

	end

end
