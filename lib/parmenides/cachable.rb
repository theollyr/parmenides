module Parmenides
  module Cachable
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :cache_distinguisher

      def cache_vars
        @cache_vars ||= []
      end

      def caching_by(distinguisher)
        @cache_distinguisher = distinguisher
      end

      def cache_variable(var)
        class_eval do
          cache_vars << var

          define_method "#{var}_to_cache" do
            fail NoMethodError, "Method #{var}_to_cache is not implemented"
          end

          define_method "#{var}_from_cache" do
            fail NoMethodError, "Method #{var}_from_cache is not implemented"
          end
        end
      end
    end

    module InstanceMethods
      def save_cache(override: nil)
        dir = environment.cache.directory
        name = send(self.class.cache_distinguisher).to_s

        vdir = File.join(dir, name)
        Dir.mkdir(vdir) unless Dir.exist?(vdir)

        vars = self.class.cache_vars
        vars = [override] if override

        vars.each do |var|
          File.open(File.join(vdir, "#{var}.cache"), "w") do |file|
            file.write(send("#{var}_to_cache"))
          end
        end
      end

      def load_cache
        dir = environment.cache.directory

        name = send(self.class.cache_distinguisher).to_s

        self.class.cache_vars.each do |var|
          file = File.join(dir, name, "#{var}.cache")
          send("#{var}_from_cache", Psych.load_file(file)) if File.exist?(file)
        end
      end
    end
  end
end
