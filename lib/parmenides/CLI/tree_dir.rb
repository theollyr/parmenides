module Parmenides
  module CLI

    class TruthDir < RootPath

      file "resources", ext: "yaml"
      file "properties", ext: "yaml"

    end

    class BranchesDir < RootPath

      file ".crown", override: "crown"

    end

    class TreeDir < RootPath

      file ".tree", override: "tree"
      file "settings", ext: "yaml"

      dir "truth", dir_class: CLI::TruthDir
      dir "branches", dir_class: CLI::BranchesDir

    end

  end
end
