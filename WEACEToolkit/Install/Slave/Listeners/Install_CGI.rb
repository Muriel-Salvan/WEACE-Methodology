# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave
  
    module Listeners
  
      class CGI
          
        # Get options of this listener
        #
        # Parameters:
        # * *ioDescription* (_ComponentDescription_): The component's description to fill
        def getDescription(ioDescription)
          ioDescription.Version = '0.0.1.20090416'
          ioDescription.Description = 'This listener creates a CGI script that routes actions to the WEACE Slave Client.'
          ioDescription.Author = 'murielsalvan@users.sourceforge.net'
          ioDescription.addVarOption(:CGIDir,
            '-d', '--cgidir <CGIDir>', String,
            '<CGIDir>: Directory where cgi scripts can be accessible through external access.',
            'Example: /home/groups/m/my/myproject/cgi-bin')
        end
        
        # Execute the installation
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
        # * *iProviderEnv* (_ProviderEnv_): The Provider specific environment
        def execute(iParameters, iProviderEnv)
          # Generate the CGI script
          lCGIScriptFileName = "#{@CGIDir}/WEACE/Actions.cgi"
          logDebug "Generate CGI script (#{lCGIScriptFileName}) ..."
          File.open(lCGIScriptFileName, 'w') do |iFile|
            iFile << "#!/usr/bin/env ruby
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

# Call WEACE Slave Client
require '#{$WEACEToolkitDir}/Slave/Client/WEACESlaveClient.rb'
if (WEACE::Slave::Client.new.executeMarshalled(lUserID, lSerializedActions))
  puts 'CGI_EXIT: OK'
else
  puts 'CGI_EXIT: ERROR'
end
"
            FileUtils.chmod(0755, lCGIScriptFileName)
          end
        end
        
      end
        
    end
    
  end

end
