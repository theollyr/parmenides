module Parmenides

	module Cachable

		def self.included base
			base.include InstanceMethods
			base.extend ClassMethods
		end

		module ClassMethods

			def cache_vars
				@cache_vars ||= []
			end

			def cache_distinguisher
				@cache_distinguisher
			end

			def caching_by distinguisher

				class_eval do
					@cache_distinguisher = distinguisher
				end

			end

			def cache_variable var

				class_eval do

					cache_vars << var

					define_method "#{var}_to_cache" do
						raise NoMethodError, "Method #{var}_to_cache is not implemented"
					end

					define_method "#{var}_from_cache" do |raw|
						raise NoMethodError, "Method #{var}_from_cache is not implemented"
					end

				end

			end

		end

		module InstanceMethods

			def save_cache

				dir = environment.cache.directory + "/#{self.class}"
				Dir.mkdir( dir ) unless Dir.exists? dir

				prename = self.send( self.class.cache_distinguisher ).to_s + "_"

				self.class.cache_vars.each do |var|
					File.open "#{dir}/#{prename}#{var}.cache", "w" do |file|
						file.write self.send( "#{var}_to_cache" )
					end
				end

			end

			def load_cache

				dir = environment.cache.directory + "/#{self.class}"
				return unless Dir.exists? dir

				prename = self.send( self.class.cache_distinguisher ).to_s + "_"

				self.class.cache_vars.each do |var|

					file = "#{dir}/#{prename}#{var}.cache"

					if File.exists? file
						self.send( "#{var}_from_cache", YAML::load_file( file ) )
					end

				end

			end

		end

	end

end
