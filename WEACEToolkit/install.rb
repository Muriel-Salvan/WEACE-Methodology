#!/usr/bin/env ruby
#
# Provide an easy-to-use installation script that can install every WEACE Toolkit component available in this distribution.
# Usage: install.rb --help
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

$WEACEToolkitVersion = '0.0.1.20090414'

require 'optparse'

# Get WEACE base directory (in absolute form), and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir(File.dirname(__FILE__))
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

require 'WEACE_Common.rb'
require 'WEACE_InstallCommon.rb'

module WEACEInstall

  # Main Installer class
  class Installer
  
    include WEACE::Logging
    include WEACE::Toolbox
    include WEACEInstall::Common
      
    # Get the list of Adapters from a directory
    #
    # Parameters:
    # * *iDirectory* (_String_): The directory to parse for Adapters
    # 
    # Return:
    # * <em>map< ProductID, map< ToolID, map< ScriptID, OptionParser > > ></em>: The list of Adapters and their description
    def getAdaptersComponents(iDirectory)
      rComponents = {}
      
      Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/*") do |iFileName1|
        if (File.directory?(iFileName1))
          lProductID = File.basename(iFileName1)
          Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/#{lProductID}/*") do |iFileName2|
            if (File.directory?(iFileName2))
              lToolID = File.basename(iFileName2)
              Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/#{lProductID}/#{lToolID}/Install_*.rb") do |iFileName3|
                if (!File.directory?(iFileName3))
                  lScriptID = File.basename(iFileName3).match(/Install_(.*)\.rb/)[1]
                  # Load description from this file
                  lDescription = getDescriptionFromFile("Install/#{iDirectory}/Adapters/#{lProductID}/#{lToolID}/Install_#{lScriptID}.rb", "WEACEInstall::#{iDirectory}::Adapters::#{lProductID}::#{lToolID}::#{lScriptID}")
                  if (lDescription != nil)
                    if (rComponents[lProductID] == nil)
                      rComponents[lProductID] = {}
                    end
                    if (rComponents[lProductID][lToolID] == nil)
                      rComponents[lProductID][lToolID] = {}
                    end
                    rComponents[lProductID][lToolID][lScriptID] = lDescription
                  end
                end
              end
            end
          end
        end
      end
      
      return rComponents
    end
    
    # Get the list of components
    #
    # Return:
    # * _ComponentDescription_: WEACE Master Server description (or nil if no component)
    # * <em>map< ProductID, map< ToolID, map< ScriptID, ComponentDescription > > ></em>: The list of WEACE Master Adapters and their description
    # * _ComponentDescription_: WEACE Slave Client description (or nil if no component)
    # * <em>map< ProductID, map< ToolID, map< ScriptID, ComponentDescription > > ></em>: The list of WEACE Slave Adapters and their description
    def getComponents
      # WEACE Master Server
      rWEACEMasterServerDesc = nil
      lRequireName = 'Install/Master/Server/Install_WEACEMasterServer.rb'
      if (File.exists?("#{$WEACEToolkitDir}/#{lRequireName}"))
        rWEACEMasterServerDesc = getDescriptionFromFile(lRequireName, 'WEACEInstall::Master::Server')
      end
      # WEACE Master Adapters
      rWEACEMasterAdaptersList = getAdaptersComponents('Master')
      # WEACE Slave Client
      rWEACESlaveClientDesc = nil
      lRequireName = 'Install/Slave/Client/Install_WEACESlaveClient.rb'
      if (File.exists?("#{$WEACEToolkitDir}/#{lRequireName}"))
        rWEACESlaveClientDesc = getDescriptionFromFile(lRequireName, 'WEACEInstall::Slave::Client')
      end
      # WEACE Slave Adapters
      rWEACESlaveAdaptersList = getAdaptersComponents('Slave')
      
      return rWEACEMasterServerDesc, rWEACEMasterAdaptersList, rWEACESlaveClientDesc, rWEACESlaveAdaptersList
    end
    
    # Get the list of installed components
    #
    # Return:
    # * _InstalledComponentDescription_: WEACE Master Server installed description (nil if not installed)
    # * <em>map< ProductID, map< ToolID, map< ScriptID, InstalledComponentDescription > > ></em>: The list of installed WEACE Master Adapters
    # * _InstalledComponentDescription_: WEACE Slave Client installed description (nil if not installed)
    # * <em>map< ProductID, map< ToolID, map< ScriptID, InstalledComponentDescription > > ></em>: The list of installed WEACE Slave Adapters
    def getInstalledComponents
      rWEACEMasterServerInstalled = nil
      rWEACEMasterAdaptersInstalled = {}
      rWEACESlaveClientInstalled = nil
      rWEACESlaveAdaptersInstalled = {}
      
      if (File.exists?("#{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb"))
        # Require the file registering WEACE Master Adapters
        begin
          require 'Master/Server/InstalledWEACEMasterAdapters.rb'
          begin
            # Get the list
            rWEACEMasterServerInstalled = WEACE::Master::getInstallationDescription
            rWEACEMasterAdaptersInstalled = WEACE::Master::getInstalledAdapters
          rescue Exception
            logErr "Error while getting installed WEACE Master Adapters from file #{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb: #{$!}"
            logErr 'This file should have been generated and kept unmodified afterwards. You can regenerate it by reinstalling WEACE Master Server and Adapters.'
          end
        rescue Exception
          logErr "Error while loading file #{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb: #{$!}"
          logErr 'This file should have been generated and kept unmodified afterwards. You can regenerate it by reinstalling WEACE Master Server and Adapters.'
        end
      end
      if (File.exists?("#{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb"))
        # Require the file registering WEACE Slave Adapters
        begin
          require 'Slave/Client/InstalledWEACESlaveAdapters.rb'
          begin
            # Get the list
            rWEACESlaveClientInstalled = WEACE::Slave::getInstallationDescription
            rWEACESlaveAdaptersInstalled = WEACE::Slave::getInstalledAdapters
          rescue Exception
            logErr "Error while getting installed WEACE Slave Adapters from file #{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb: #{$!}"
            logErr 'This file should have been generated and kept unmodified afterwards. You can regenerate it by reinstalling WEACE Slave Client and Adapters.'
          end
        rescue Exception
          logErr "Error while loading file #{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb: #{$!}"
          logErr 'This file should have been generated and kept unmodified afterwards. You can regenerate it by reinstalling WEACE Slave Client and Adapters.'
        end
      end
      
      return rWEACEMasterServerInstalled, rWEACEMasterAdaptersInstalled, rWEACESlaveClientInstalled, rWEACESlaveAdaptersInstalled
    end
    
    # Output information of a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # * *iComponentDescription* (_ComponentDescription_): The description
    # * *iInstalledComponentDescription* (_InstalledComponentDescription_): The installation description (can be nil if not installed)
    # * *iNotInstalledMessage* (_String_): Message to add if not installed.
    def outputComponent(iComponentName, iComponentDescription, iInstalledComponentDescription, iNotInstalledMessage)
        puts "* Component: #{iComponentName}"
        puts "  * Version: #{iComponentDescription.Version}"
        puts "  * Description: #{iComponentDescription.Description}"
        puts "  * Author: #{iComponentDescription.Author}"
        if (iInstalledComponentDescription != nil)
          puts "  * Installed v#{iInstalledComponentDescription.Version} on #{iInstalledComponentDescription.Date}"
        else
          puts "  * Not installed#{iNotInstalledMessage}"
        end
        puts '  * Options:'
        puts iComponentDescription.Options.summarize
        puts ''
    end

    # Outputs the list of components
    def outputComponents
      lWEACEMasterServerDesc, lWEACEMasterAdaptersList, lWEACESlaveClientDesc, lWEACESlaveAdaptersList = getComponents
      lWEACEMasterServerInstalled, lWEACEMasterAdaptersInstalledList, lWEACESlaveClientInstalled, lWEACESlaveAdaptersInstalledList = getInstalledComponents
      puts ''
      puts 'Installable components:'
      # WEACE Master Server
      if (lWEACEMasterServerDesc != nil)
        outputComponent('WEACEMasterServer', lWEACEMasterServerDesc, lWEACEMasterServerInstalled, '')
      end
      # WEACE Master Adapters
      if (!lWEACEMasterServerInstalled)
        lInstallFirstWEACEMasterServerMessage = ' (Install WEACEMasterServer first)'
      else
        lInstallFirstWEACEMasterServerMessage = ''
      end
      lWEACEMasterAdaptersList.each do |iProductID, iProductAdapters|
        iProductAdapters.each do |iToolID, iToolAdapters|
          iToolAdapters.each do |iScriptID, iDescription|
            lInstalledDescription = nil
            if ((lWEACEMasterAdaptersInstalledList[iProductID] != nil) and
                (lWEACEMasterAdaptersInstalledList[iProductID][iToolID] != nil) and
                (lWEACEMasterAdaptersInstalledList[iProductID][iToolID][iScriptID] != nil))
              lInstalledDescription = lWEACEMasterAdaptersInstalledList[iProductID][iToolID][iScriptID]
            end
            outputComponent("WEACEMasterAdapter.#{iProductID}.#{iToolID}.#{iScriptID}", iDescription, lInstalledDescription, lInstallFirstWEACEMasterServerMessage)
          end
        end
      end
      # WEACE Slave Client
      if (lWEACESlaveClientDesc != nil)
        outputComponent('WEACESlaveClient', lWEACESlaveClientDesc, lWEACESlaveClientInstalled, '')
      end
      # WEACE Slave Adapters
      if (!lWEACESlaveClientInstalled)
        lInstallFirstWEACESlaveClientMessage = ' (Install WEACESlaveClient first)'
      else
        lInstallFirstWEACESlaveClientMessage = ''
      end
      lWEACESlaveAdaptersList.each do |iProductID, iProductAdapters|
        iProductAdapters.each do |iToolID, iToolAdapters|
          iToolAdapters.each do |iScriptID, iDescription|
            lInstalledDescription = nil
            if ((lWEACESlaveAdaptersInstalledList[iProductID] != nil) and
                (lWEACESlaveAdaptersInstalledList[iProductID][iToolID] != nil) and
                (lWEACESlaveAdaptersInstalledList[iProductID][iToolID][iScriptID] != nil))
              lInstalledDescription = lWEACESlaveAdaptersInstalledList[iProductID][iToolID][iScriptID]
            end
            outputComponent("WEACESlaveAdapter.#{iProductID}.#{iToolID}.#{iScriptID}", iDescription, lInstalledDescription, lInstallFirstWEACESlaveClientMessage)
          end
        end
      end
    end
  
    # Register a new WEACE Master Adapter
    #
    # Parameters:
    # * *iFileName* (_String_): File where Adapters are registered
    # * *iProductID* (_String_): The Product ID
    # * *iToolID* (_String_): The Tool ID
    # * *iScriptID* (_String_): The Script ID
    # * *iDescription* (_ComponentDescription_): The description
    def registerNewAdapter(iFileName, iProductID, iToolID, iScriptID, iDescription)
      log "Register WEACE Master Adapter #{iProductID}.#{iToolID}.#{iScriptID} in file #{iFileName} ..."
      modifyFile(iFileName,
        nil,
        "
      lDesc = InstalledComponentDescription.new
      lDesc.Date = '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
      lDesc.Version = '#{iDescription.Version}'
      lDesc.Description = '#{iDescription.Description}'
      lDesc.Author = '#{iDescription.Author}'
      if (rInstalledAdapters['#{iProductID}'] == nil)
        rInstalledAdapters['#{iProductID}'] = {}
      end
      if (rInstalledAdapters['#{iProductID}']['#{iToolID}'] == nil)
        rInstalledAdapters['#{iProductID}']['#{iToolID}'] = {}
      end
      rInstalledAdapters['#{iProductID}']['#{iToolID}']['#{iScriptID}'] = lDesc
",
        /# === INSERT ===/,
        :CheckMatch => ["\n",
"      lDesc = InstalledComponentDescription.new\n",
/      lDesc.Date = /,
"      lDesc.Version = '#{iDescription.Version}'\n",
"      lDesc.Description = '#{iDescription.Description}'\n",
"      lDesc.Author = '#{iDescription.Author}'\n",
"      if (rInstalledAdapters['#{iProductID}'] == nil)\n",
"        rInstalledAdapters['#{iProductID}'] = {}\n",
"      end\n",
"      if (rInstalledAdapters['#{iProductID}']['#{iToolID}'] == nil)\n",
"        rInstalledAdapters['#{iProductID}']['#{iToolID}'] = {}\n",
"      end\n",
"      rInstalledAdapters['#{iProductID}']['#{iToolID}']['#{iScriptID}'] = lDesc\n",
"\n")
    end

    # Get the provider specific environment, generated by the installation of WEACE Master Server or WEACE Slave Client
    #
    # Parameters:
    # * *iProviderEnvFileName* (_String_): Name of the file containing the provider specific environment
    # * *iClassName* (_String_): ProviderEnv class name
    # Return:
    # * _ProviderEnv_: The specific environment
    def getProviderEnv(iProviderEnvFileName, iClassName)
      log "Read the provider environment generated during the WEACE Master Server's installation (#{iProviderEnvFileName}) ..."
      begin
        require iProviderEnvFileName
      rescue Exception
        logErr "Unable to load the environment from file \'#{iProviderEnvFileName}\'. Make sure the file is present and is set in one of the $RUBYLIB paths, or the current path."
        raise
      end
      return eval("#{iClassName}.new")
    end
    
    # Install a given component from a file
    #
    # Parameters:
    # * *iComponentName* (_String_): The component name
    # * *iFileName* (_String_): The file name (relative to WEACE Toolkit directory)
    # * *iClassName* (_String_): The class name of the installer
    # * *iParameters* (<em>list<String></em>): The list of parameters to give the installer
    # * *iProviderEnv* (_ProviderEnv_): The specific provider environment, or nil if none
    def installComponentFromFile(iComponentName, iFileName, iClassName, iParameters, iProviderEnv)
      log "Install Component #{iComponentName} with parameters: #{iParameters.inspect}"
      lInstaller, lAdditionalArgs = getInitializedInstallerFromFile(iFileName, iClassName, iParameters)
      # And now execute the installer code
      if (iProviderEnv != nil)
        lInstaller.execute(lAdditionalArgs, iProviderEnv)
      else
        lInstaller.execute(lAdditionalArgs)
      end
    end
    
    # Install a given component
    #
    # Parameters:
    # * *iComponent* (_String_): Component name
    # * *iParameters* (<em>list<String></em>): The list of parameters for this installation
    def installComponent(iComponent, iParameters)
      log "=== Install Component #{iComponent}(#{iParameters.inspect}) ..."
      case iComponent
      when 'WEACEMasterServer'
        installComponentFromFile(iComponent, 'Install/Master/Server/Install_WEACEMasterServer.rb', 'WEACEInstall::Master::Server', iParameters, nil)
      when 'WEACESlaveClient'
        installComponentFromFile(iComponent, 'Install/Slave/Client/Install_WEACESlaveClient.rb', 'WEACEInstall::Slave::Client', iParameters, nil)
      else
        # Format of type WEACE{Master|Slave}Adapter.<ProductID>.<ToolID>.<ScriptID>
        lMasterMatch = iComponent.match(/^WEACEMasterAdapter\.(.*)\.(.*)\.(.*)$/)
        if (lMasterMatch != nil)
          lProductID, lToolID, lScriptID = lMasterMatch[1..3]
          # Got a WEACE Master Adapter installation
          # First, check that WEACE Master Server is installed
          if (File.exists?("#{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb"))
            # Get the Provider specific environment 
            lProviderEnv = getProviderEnv('Install/Master/ProviderEnv.rb', 'WEACEInstall::Master::ProviderEnv')
            lFileName = "Install/Master/Adapters/#{lProductID}/#{lToolID}/Install_#{lScriptID}.rb"
            lClassName = "WEACEInstall::Master::Adapters::#{lProductID}::#{lToolID}::#{lScriptID}"
            installComponentFromFile(iComponent, lFileName, lClassName, iParameters, lProviderEnv)
            # Register this Adapter
            lDescription = getDescriptionFromFile(lFileName, lClassName)
            registerNewAdapter("#{$WEACEToolkitDir}/Master/Server/InstalledWEACEMasterAdapters.rb", lProductID, lToolID, lScriptID, lDescription)
          else
            logExc RuntimeError, 'You must first install WEACE Master Server.'
          end
        else
          lSlaveMatch = iComponent.match(/^WEACESlaveAdapter\.(.*)\.(.*)\.(.*)$/)
          if (lSlaveMatch != nil)
            lProductID, lToolID, lScriptID = lSlaveMatch[1..3]
            # Got a WEACE Slave Adapter installation
            if (File.exists?("#{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb"))
            # Get the Provider specific environment 
              lProviderEnv = getProviderEnv('Install/Slave/ProviderEnv.rb', 'WEACEInstall::Slave::ProviderEnv')
              lFileName = "Install/Slave/Adapters/#{lProductID}/#{lToolID}/Install_#{lScriptID}.rb"
              lClassName = "WEACEInstall::Slave::Adapters::#{lProductID}::#{lToolID}::#{lScriptID}"
              installComponentFromFile(iComponent, lFileName, lClassName, iParameters, lProviderEnv)
              # Register this Adapter
              lDescription = getDescriptionFromFile(lFileName, lClassName)
              registerNewAdapter("#{$WEACEToolkitDir}/Slave/Client/InstalledWEACESlaveAdapters.rb", lProductID, lToolID, lScriptID, lDescription)
            else
              logExc RuntimeError, 'You must first install WEACE Slave Client.'
            end
          else
            logExc RuntimeError, "Unknown component named #{iComponent}: check possible components with --list option."
          end
        end
      end
      log "=== Component #{iComponent}(#{iParameters.inspect}) installed successfully."
    end
    
    # Get options of this installer
    #
    # Return:
    # * _OptionParser_: The options parser
    def getOptions
      rOptions = OptionParser.new
      
      # Options are defined here
      rOptions.on('-h', '--help',
        'Display help on this script.') do
        puts rOptions
      end
      rOptions.on('-i', '--install <Component>', String,
        '<Component>: Any value returned by the --list output.',
        'Install a given component.') do |iArg|
        @ComponentToInstall = iArg
      end
      rOptions.on('-l', '--list',
        'Give a list of all components in this distribution.') do
        @OutputComponents = true
      end
      rOptions.on('-v', '--version',
        'Get version of this WEACE Toolkit distribution.') do
        @OutputVersion = true
      end
      rOptions.on('--',
        'Following -- are the parameters specific to the installation of a given component (check each component\'s options with --list).')
      
      return rOptions
    end
    
    # Execute the installer
    #
    # Parameters:
    # * *iParameters* (<em>list<String></em>): Parameters given to the installer
    def execute(iParameters)
      # Store a log file in the Install directory
      $LogFile = "#{$WEACEToolkitDir}/Install/install.log"
      lOptions = getOptions
      if (iParameters.size == 0)
        puts lOptions
      else
        # Parse options
        lInstallerArgs, lAdditionalArgs = splitParameters(iParameters)
        lSuccess = true
        begin
          lOptions.parse(lInstallerArgs)
        rescue
          puts "Error while parsing arguments: #{$!}"
          puts lOptions
          lSuccess = false
        end
        if (lSuccess)
          # Execute what was asked by the options
          if (@OutputVersion)
            puts $WEACEToolkitVersion
          end
          if (@OutputComponents)
            outputComponents
          end
          if (@ComponentToInstall != nil)
            installComponent(@ComponentToInstall, lAdditionalArgs)
          end
        end
      end
    end
    
  end
  
end

# Create the installer
lInstaller = WEACEInstall::Installer.new
# Execute it
lInstaller.execute(ARGV)
