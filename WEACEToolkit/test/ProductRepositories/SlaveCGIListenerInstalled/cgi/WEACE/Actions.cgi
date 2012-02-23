#!/usr/bin/env ruby
# This file has been generated by the installer of the CGI listener from WEACE Toolkit.
# Do not modify it.
# It is used to route actions to WEACE Slave Client.
#
# More info on http://weacemethod.sourceforge.net

# Write header
puts 'Content-type: text/html'
puts ''
puts ''

# Redirect STDERR on STDOUT
$stderr.reopen $stdout

# Get the parameters
require 'cgi'
lCgi = CGI.new
lUserID = lCgi['userid']
lSerializedActions = lCgi['actions']

# Load WEACE environment
require '%{WEACEEnvFile}'
# Call WEACE Slave Client library directly
require 'rUtilAnts/Platform'
RUtilAnts::Platform::install_platform_on_object
require 'rUtilAnts/Misc'
RUtilAnts::Misc::install_misc_on_object
require 'WEACEToolkit/Slave/Client/WEACESlaveClient'
lError = WEACE::Slave::Client.new.executeMarshalled(lUserID, lSerializedActions)
if (lError == nil)
  puts 'CGI_EXIT: OK'
else
  puts "CGI_EXIT: ERROR: #{lError}"
end
