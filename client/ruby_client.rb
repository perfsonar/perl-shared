#! /usr/bin/ruby
 
# == Name  
# ruby_client.rb  
#  
# == Synopsis 
#   Simple Ruby perfSONAR client 
#
# == Usage 
#  ./ruby_client.rb [ -h | --help ]  
#                   [ -r | --request | < ] request.xml 
#                   [ -s | --service | < ] http://HOST:PORT/ENDPOINT
#
# == Options
#  -h,--help::              Show help  
#  -s,--service=SERVICE::   Service name 
#  -r,--request=REQUEST::   Request file name 
#
# == Author
#   Sander Boele, sanderb@sara.nl
#   Jason Zurawski, zurawski@internet2.edu
#
# == Copyright
#   Copyright (c) 2011, SARA and Internet2
#
#   All rights reserved.
#
#   You should have received a copy of the Internet2 Intellectual Property
#   Framework along with this software.  If not, see
#   <http://www.internet2.edu/membership/ip.html>

require 'rdoc/usage'  
require 'optparse'  
require 'ostruct' 
require 'net/https'
require 'uri'

options = OpenStruct.new()  
opts = OptionParser.new()  
opts.on("-h","--help", "Display the usage information") {RDoc::usage('usage')}  
opts.on("-r","--request", "=REQUEST",  "Request file name") {|argument| options.request = argument}  
opts.on("-s","--service", "=SERVICE",  "Service name") {|argument| options.service = argument} 
opts.parse! rescue RDoc::usage('usage')

uri = URI.parse(options.service)
xmlorig = IO.read(options.request)

# Remove XML declaration line (if present)
xml = xmlorig.gsub /^.*<\?xml.*/i, ""

SOAP_HEAD = %{ <SOAP-ENV:Envelope xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header/><SOAP-ENV:Body> }
SOAP_FOOT = %{ </SOAP-ENV:Body></SOAP-ENV:Envelope> }

http = Net::HTTP.new(uri.host, uri.port)
http.open_timeout = 30 # in seconds
http.read_timeout = 30 # in seconds

request = Net::HTTP::Post.new(uri.request_uri)
request.initialize_http_header({"Content-Type" => "text/xml"})
request.body = SOAP_HEAD + xml + SOAP_FOOT

response = http.request(request)

puts response.body
