require 'rest_client'
require 'nokogiri'

module Parmenides

	class Client

		attr_reader :endpoint
		attr_reader :rclient

		private :rclient

		def initialize endpoint

			@endpoint = endpoint
			@rclient = ::RestClient::Resource.new endpoint

		end

		def query qstring

			begin
				response = rclient.post query: qstring
			rescue => e
				raise e.response
			end
			
			doc = Nokogiri::XML( response.to_str )

			# puts response.to_str

			variables = doc.xpath( "//xmlns:variable/@name" ).map do |xattr|
				xattr.value
			end

			# p variables

			doc.xpath( "//xmlns:result" ).map do |xres|

				variables.map do |var|

					xelm = xres.xpath( 'xmlns:binding[@name="' + var + '"]/*' ).first

					val = case xelm.name
					when "uri"
						::RDF::URI.new xelm.content
					else
						xelm.content
					end

					[ var.to_sym, val ]

				end.to_h

			end

		end

	end

end
