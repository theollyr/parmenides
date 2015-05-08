module Parmenides

	module CLI

		class BranchDir < RootPath

			file ".branch", override: "branch"

			dir "cache"
			dir "seasons"

		end

	end

end
