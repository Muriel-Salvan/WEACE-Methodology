# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Master
  
    class WEACEMasterServer
    
      include WEACEInstall::Common
      include WEACE::Common
      
      # Install for real.
      # This is called only when check method returned no error.
      #
      # Return:
      # * _Exception_: An error, or nil in case of success
      def execute
        rError = nil

        rError, lProviderEnv = getProviderEnv('Master', @ProviderID, @AdditionalParameters)
        if (rError == nil)
          # Generate the WEACE environment file
          generateWEACEEnvFile
          if (lProviderEnv[:Shell] != nil)
            # Create the directory for Shell scripts
            require 'fileutils'
            FileUtils.mkdir_p(lProviderEnv[:Shell][:InternalDirectory])
            # Create the script that displays what is installed
            lShowComponentsFileName = "#{lProviderEnv[:Shell][:InternalDirectory]}/ShowWEACEMasterInfo.sh"
            File.open(lShowComponentsFileName, 'w') do |oFile|
              oFile << "\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Master Server
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Master/DumpInfo'
  WEACE::Master::DumpInfo.new.dumpTerminal
rescue Exception
  puts \"WEACE Master Installation is corrupted: \#{$!}\"
end
"
            end
            FileUtils.chmod(0755, lShowComponentsFileName)
          end
          if (lProviderEnv[:CGI] != nil)
            # Generate the cgi script that will give details about the installed WEACE Master Adapters
            lShowComponentsFileName = "#{lProviderEnv[:CGI][:InternalDirectory]}/WEACE/ShowWEACEMasterInfo.cgi"
            logDebug "Generate CGI script that shows installed WEACE Master Adapters (#{lShowComponentsFileName}) ..."
            require 'fileutils'
            FileUtils.mkdir_p(File.dirname(lShowComponentsFileName))
            File.open(lShowComponentsFileName, 'w') do |oFile|
              oFile << "\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Master Server
\# Print header
puts 'Content-type: text/html'
puts ''
puts ''
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Master/DumpInfo'
  WEACE::Master::DumpInfo.new.dumpHTML
rescue Exception
  puts \"WEACE Master Installation is corrupted: \#{$!}\"
end
"
            end
            FileUtils.chmod(0755, lShowComponentsFileName)
          end
          # Generate directory that will store SlaveClients' queues
          FileUtils::mkdir_p("#{@WEACEVolatileDir}/MasterServer/SlaveClientQueues")
          logInfo 'WEACE Master Server installed successfully. You can install WEACE Master Adapters.'
        end

        return rError
      end

      # Get the default configuration
      #
      # Return:
      # * _String_: The default configuration text to put in the configuration file.
      def getDefaultConfig
        return "
{
  \# Log file used
  \# String
  \# :LogFile => '/var/log/WEACEMasterServer.log',

  \# List of WEACE Slave Clients to contact
  \# list <
  \#   {
  \#     :Type => <ClientType>,
  \#     :Tools => list < <ToolName> >
  \#   }
  \# >
  :WEACESlaveClients => [
  \#  {
  \#    :Type => 'Local',
  \#    :Tools => [
  \#      Tools::Wiki,
  \#      Tools::TicketTracker
  \#    ]
  \#  }
  ]
}
"
      end

    end
  
  end
  
end
