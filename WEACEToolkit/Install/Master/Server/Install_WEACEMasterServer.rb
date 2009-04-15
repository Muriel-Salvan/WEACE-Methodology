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
  
    # Proxy class loading specifics of this provider type
    class ProviderConfig
    
      # Internal directory where we can put CGI scripts that give external views of the configuration
      attr_accessor :CGIDir
      
      # External URL accessing the cgi scripts directory
      attr_accessor :CGIURL
      
    end

    class Server
    
      Version = '0.0.1.20090414'
      Description = 'The WEACE Master Server.'
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
        Dir.glob("#{$WEACEToolkitDir}/Install/Master/Providers/*.rb") do |iFileName|
          lProviderID = File.basename(iFileName).match(/(.*)\.rb/)[1]
          # Require the Provider specific installation file
          lOptions = getDescriptionFromFile("Install/Master/Providers/#{lProviderID}.rb", "WEACEInstall::Master::Providers::#{lProviderID}").Options
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
        lProviderInstaller, lAdditionalArgs = getInitializedInstallerFromFile("Install/Master/Providers/#{@ProviderID}.rb", "WEACEInstall::Master::Providers::#{@ProviderID}", iParameters)
        # Populate environment specifics
        lProviderConfig = WEACEInstall::Master::ProviderConfig.new
        lProviderInstaller.getRuntimeWEACEMasterServerEnvironment(lProviderConfig)
        # Generate the cgi script that will give details about the registered WEACE Slave Clients
        lShowClientsFileName = "#{lProviderConfig.CGIDir}/WEACE/ShowKnownSlaveClients.cgi"
        log "Generate CGI script that shows known WEACE Slave Clients (#{lShowClientsFileName}) ..."
        require 'fileutils'
        FileUtils.mkdir_p(File.dirname(lShowClientsFileName))
        File.open(lShowClientsFileName, 'w') do |iFile|
          iFile << "#!/usr/bin/env ruby
# This file has been generated by the installation of WEACE Master Server
$LOAD_PATH << '#{$WEACEToolkitDir}'
require 'Master/Server/ShowKnownSlaveClients.rb'
# Print header
puts 'Content-type: text/html'
puts ''
puts ''
WEACE::Master::dumpKnownSlaveClients_HTML
"
        end
        FileUtils.chmod(0755, lShowClientsFileName)
        # Generate the cgi script that will give details about the installed WEACE Master Adapters
        lShowAdaptersFileName = "#{lProviderConfig.CGIDir}/WEACE/ShowInstalledMasterAdapters.cgi"
        log "Generate CGI script that shows installed WEACE Master Adapters (#{lShowAdaptersFileName}) ..."
        File.open(lShowAdaptersFileName, 'w') do |iFile|
          iFile << "#!/usr/bin/env ruby
# This file has been generated by the installation of WEACE Master Server
$LOAD_PATH << '#{$WEACEToolkitDir}'
require 'Master/Server/ShowInstalledMasterAdapters.rb'
# Print header
puts 'Content-type: text/html'
puts ''
puts ''
WEACE::Master::dumpInstalledMasterAdapters_HTML
"
        end
        FileUtils.chmod(0755, lShowAdaptersFileName)
        # Generate the installation's environment file that will be used by Adapters' installers
        lEnvProviderFileName = "#{$WEACEToolkitDir}/Install/Master/ProviderEnv.rb"
        log "Generate environment file that will be used by WEACE Master Adapters' installers (#{lEnvProviderFileName}) ..."
        File.open(lEnvProviderFileName, 'w') do |iFile|
          iFile << "# This file has been generated by Install_WEACEMasterServer.rb.
# It is used to give the environment of this provider to the WEACE Master Adapters installers.
# This avoids developers to always give those parameters to any of the adapters installers.
# Its content depends on the WEACE Master Server type (SourceForge, RubyForge...)
module WEACEInstall

  module Master

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
        # Generate the file where WEACE Master Adapters will register themselves.
        lAdaptersRegisterFile = "#{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb"
        log "Generate file where WEACE Master Adapters register themselves (#{lAdaptersRegisterFile}) ..."
        File.open(lAdaptersRegisterFile, 'w') do |iFile|
          iFile << "
# This file is generated by the installation of WEACE Master Server, and completed by the installation of each WEACE Master Adapter.
# Do not modify it.
# It contains all installed WEACE Master Adapters information.

module WEACE

  module Master
  
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
  
    # Get the list of installed WEACE Master Adapters
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
        log 'WEACE Master Server installed successfully. You can install WEACE Master Adapters.'
        return true
      end
    
    end
  
  end
  
end
