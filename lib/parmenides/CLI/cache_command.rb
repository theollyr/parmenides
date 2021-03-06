module Parmenides
  module CLI
    class Cache < Thor

      desc "build", "builds cache for later use"
      option :only_resources, aliases: '-r', type: :boolean
      option :only_properties, aliases: '-p', type: :boolean
      option :leaf, aliases: '-l', type: :array
      option :rebuild, type: :boolean
      def build

        files = TreeDir.new options[:dir]

        conf = ::Parmenides::Environment.empty
        conf.configure_from_hash Psych.load_file( files.settings )

        selected_branch = File.read( files.branches.crown ).chomp

        branches = if selected_branch == "all"
          CLI::Branch.scan_dir files.branches.root
        else

          selected_branch.split("*").map do |b|

            branch = CLI::Branch.new b
            branch.load File.join( files.branches.root, b )

            branch

          end

        end

        branches.each do |branch|

          puts "Building cache for the branch #{branch.name}..."

          conf.cache.directory = branch.root.cache.root
          conf.other.languages = branch.name.split( "_" )

          leaves = if options[:leaf]
            options[:leaf]
          else
            branch.leaves
          end

          leaves.each do |ibx_name|

            puts "Working on the leaf #{ibx_name}..."

            ibx = ::Parmenides::Infobox.new name: ibx_name, environment: conf
            ibx.load_cache unless options[:rebuild]
            
            if options[:only_resources]
              ibx.save_cache override: "resources"
              next
            end

            if options[:only_properties]
              ibx.save_cache override: "properties"
              next
            end

            ibx.save_cache

            puts

          end

        end

      end

      desc "rebuild", "rebuilds cache for later use"
      option :only_resources, aliases: '-r', type: :boolean
      option :only_properties, aliases: '-p', type: :boolean
      option :leaf, aliases: '-l', type: :array
      def rebuild
        options[:rebuild] = true
        invoke :build, [], options
      end

    end
  end
end
