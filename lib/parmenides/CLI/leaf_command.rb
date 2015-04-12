module Parmenides

	module CLI

		class Leaf < Thor

			desc "add NAME", "adds new leaf (infobox) with NAME to the currect branch"
			def add name

				files = TreeDir.new options[:dir]

				get_branches( files ).each do |branch|
					branch.add_leaf name
				end

			end

			desc "remove NAME", "removes the leaf with NAME from the current branch"
			def remove name

				files = TreeDir.new options[:dir]

				get_branches( files ).each do |branch|
					branch.remove_leaf name
				end

			end

			no_tasks do

				def get_branches files

					selected_branch = File.read( files.branches.crown ).chomp

					if selected_branch == "all"
						CLI::Branch.scan_dir files.branches.root
					else

						branch = CLI::Branch.new selected_branch
						branch.load File.join( files.branches.root, selected_branch )
						[branch]

					end

				end

			end

		end

	end

end
