module Parmenides
  module CLI
    class RootPath
      class << self

        @files = []
        @dirs = []

        def file name, ext:nil, override:nil

          mname = name
          mname = override if override

          define_method mname do

            old = self.instance_variable_get "@#{mname}"
            return old unless old.nil?

            file = name
            file += ".#{ext}" unless ext.nil?
            file = File.join self.root, file

            # @files << file

            self.instance_variable_set "@#{mname}", file

          end

        end

        def dir name, dir_class: RootPath

          define_method name do
            
            old = self.instance_variable_get "@#{name}" 
            return old unless old.nil?

            path = File.join self.root, name
            dir = dir_class.new  path

            # @dirs << dir

            self.instance_variable_set "@#{name}", dir

          end

        end

      end

      def initialize root
        @root = root
      end

      attr_reader :root
      
    end
  end
end
