module Parmenides

	module Mappers

		class Mapper

			attr_accessor :preprocessor, :processor, :finisher

			def initialize preprocessor:nil, processor:nil, finisher:nil

				@preprocessor = preprocessor
				@processor = processor
				@finisher = finisher

			end

			def mapping_for data
				mapping_process_for( data )[:at_end]
			end

			def mapping_process_for data

				process = {}

				process[:at_beginning] = data

				process[:after_prepocessing] = data = call_for :preprocessor, data
				process[:after_processing] = data = call_for :processor, data

				process[:at_end] = call_for :finisher, data

				process

			end

			def call_for processor_name, data

				if send( processor_name ).nil?
					data
				else
					send( processor_name ).call data
				end

			end
			private :call_for

		end

	end

end

