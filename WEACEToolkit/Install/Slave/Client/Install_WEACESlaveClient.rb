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
  
    # Proxy class loading specifics of this provider type
    class ProviderConfig
    
      # Internal directory where we can put CGI scripts that give external views of the configuration
      attr_accessor :CGIDir
      
      # External URL accessing the cgi scripts directory
      attr_accessor :CGIURL
      
    end

    class Client
    
      Version = '0.0.1.20090414'
      Description = 'The WEACE Slave Client.'
      Author = 'murielsalvan@users.sourceforge.net'
      
      include WEACE::Logging
      include WEACEInstall::Common
      
      # Get options of this installer
      #
      # Parameters:
      # * *ioDescription* (_ComponentDescription_): The component's description to fill
      def getDescription(ioDescription)
        ioDescription.Version = Version
        ioDescription.Description = Description
        ioDescription.Author = Author
        # Get options of all available provider types
        lProviderOptions = {}
        Dir.glob("#{$WEACEToolkitDir}/Install/Slave/Providers/*.rb") do |iFileName|
          lProviderID = File.basename(iFileName).match(/(.*)\.rb/)[1]
          # Require the Provider specific installation file
          lOptions = getDescriptionFromFile("Install/Slave/Providers/#{lProviderID}.rb", "WEACEInstall::Slave::Providers::#{lProviderID}").Options
          if (lOptions != nil)
            lProviderOptions[lProviderID] = lOptions
          end
        end
        # If there are no specifics for Providers, don't ask for the --providertype option
        if (lProviderOptions.size > 0)
          lOptionsDisplay = []
          lProviderOptions.keys.sort.each do |iProviderID|
            iOptions = lProviderOptions[iProviderID]
            lOptionsDisplay << "* Provider type: #{iProviderID}"
            iOptions.summarize.each do |iLine|
              # Remove trailing \n
              lOptionsDisplay << iLine.chomp
            end
          end
          # Display options
          ioDescription.addVarOption(:ProviderID, 
            '-t', '--providertype <ProvType>', String,
            '<ProvType>: Type of provider where we install components.',
            "Here is the list of #{lProviderOptions.size} available provider types and their corresponding options:",
            *lOptionsDisplay)
          ioDescription.addOption('--',
            'Following -- are the parameters dependent on each provider type.')
        end
      end
      
      # Execute the installation
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def execute(iParameters)
        log "Read specific type #{@ProviderID} configuration ..."
        lProviderInstaller, lAdditionalArgs = getInitializedInstallerFromFile("Install/Slave/Providers/#{@ProviderID}.rb", "WEACEInstall::Slave::Providers::#{@ProviderID}", iParameters)
        # Populate environment specifics
        lProviderConfig = WEACEInstall::Slave::ProviderConfig.new
        lProviderInstaller.getRuntimeWEACESlaveClientEnvironment(lProviderConfig)
        # Generate the cgi script that will give details about the installed WEACE Slave Adapters
        lShowAdaptersFileName = "#{lProviderConfig.CGIDir}/WEACE/ShowInstalledSlaveAdapters.cgi"
        log "Generate CGI script that shows installed WEACE Slave Adapters (#{lShowAdaptersFileName}) ..."
        require 'fileutils'
        FileUtils.mkdir_p(File.dirname(lShowAdaptersFileName))
        File.open(lShowAdaptersFileName, 'w') do |iFile|
          iFile << "#!/usr/bin/env ruby
# This file has been generated by the installation of WEACE Master Server
$LOAD_PATH << '#{$WEACEToolkitDir}'
require 'Slave/Client/ShowInstalledSlaveAdapters.rb'
# Print header
puts 'Content-type: text/html'
puts ''
puts ''
WEACE::Slave::dumpInstalledSlaveAdapters_HTML
"
        end
        # Generate the installation's environment file that will be used by Adapters' installers
        lEnvProviderFileName = "#{$WEACEToolkitDir}/Install/Slave/ProviderEnv.rb"
        log "Generate environment file that will be used by WEACE Slave Adapters' installers (#{lEnvProviderFileName}) ..."
        File.open(lEnvProviderFileName, 'w') do |iFile|
          iFile << "# This file has been generated by Install_WEACESlaveServer.rb.
# It is used to give the environment of this provider to the WEACE Slave Adapters installers.
# This avoids developers to always give those parameters to any of the adapters installers.
# Its content depends on the WEACE Slave Client type (SourceForge, RubyForge...)
module WEACEInstall

  module Slave

    class ProviderEnv
    
      attr_reader :ProviderType
      attr_reader :CGIURL
    
      # Constructor
      def initialize
        @ProviderType = '#{@ProviderID}'
        @CGIURL = '#{lProviderConfig.CGIURL}'
      end
      
    end
    
  end
  
end
"
        end
        # Generate the file where WEACE Slave Adapters will register themselves.
        lAdaptersRegisterFile = "#{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb"
        log "Generate file where WEACE Slave Adapters register themselves (#{lAdaptersRegisterFile}) ..."
        File.open(lAdaptersRegisterFile, 'w') do |iFile|
          iFile << "
# This file is generated by the installation of WEACE Slave Client, and completed by the installation of each WEACE Slave Adapter.
# Do not modify it.
# It contains all installed WEACE Slave Adapters information.

module WEACE

  module Slave
  
    # Get the installation description
    #
    # Return:
    # * _InstalledComponentDescription_: The installation description
    def self.getInstallationDescription
      rDesc = InstalledComponentDescription.new

      rDesc.Date = '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
      rDesc.Version = '#{Version}'
      rDesc.Description = '#{Description}'
      rDesc.Author = '#{Author}'

      return rDesc
    end
  
    # Get the list of installed WEACE Slave Adapters
    #
    # Return:
    # * <em>map< ProductID, map< ToolID, map< ScriptID, InstalledComponentDescription> > > ></em>: The registered Adapters.
    def self.getInstalledAdapters
      rInstalledAdapters = {}
      
      # === INSERT ===
      # Don't remove the previous marker as it tells where to insert following adapters in this file.
      
      return rInstalledAdapters
    end
    
  end
  
end
"
        end
        log 'WEACE Slave Client installed successfully. You can install WEACE Slave Adapters.'
        return true
      end
    
    end
  
  end
  
end
