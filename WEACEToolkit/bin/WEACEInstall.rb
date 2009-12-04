#!/usr/bin/env ruby
#
# Provide an easy-to-use installation script that can install every WEACE Toolkit component available in this distribution.
# Usage: install.rb --help
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'optparse'

require 'rUtilAnts/Misc'
RUtilAnts::Misc::initializeMisc
require 'rUtilAnts/Platform'
RUtilAnts::Platform::initializePlatform

require 'WEACE_Common.rb'
require 'Install/WEACE_InstallCommon.rb'

module WEACEInstall

  # Main Installer class
  class Installer
  
    include WEACE::Toolbox
    include WEACEInstall::Common

    # Constructor
    def initialize
      # Registered installable master and slave adapters
      # map< String,    map< String, nil > >
      # map< ProductID, map< ToolID, nil > >
      @MasterAdapters = {}
      @SlaveAdapters = {}
      # The set of installable components, as written by the user on the command line, and the corresponding plugin
      # map< String, [ String, String ] >
      # map< ComponentFullName, [ iCategoryName, iPluginName ] >
      @InstallableComponents = {}
      # Initialize logging
      require 'rUtilAnts/Logging'
      RUtilAnts::Logging::initializeLogging($WEACEToolkitDir, 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
      # Store a log file in the Install directory
      setLogFile("#{$WEACEToolkitDir}/Install/install.log")
      # Read plugins
      require 'rUtilAnts/Plugins'
      @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
      # Master Server
      parseWEACEPluginsFromDir('Master/Server', "#{$WEACEToolkitDir}/Install/Master/Server", 'WEACEInstall::Master')
      # Master Providers
      parseWEACEPluginsFromDir('Master/Providers', "#{$WEACEToolkitDir}/Install/Master/Providers", 'WEACEInstall::Master::Providers', false)
      # Master Adapters
      parseAdapters('Master', @MasterAdapters)
      # Slave Client
      parseWEACEPluginsFromDir('Slave/Client', "#{$WEACEToolkitDir}/Install/Slave/Client", 'WEACEInstall::Slave')
      # Slave Providers
      parseWEACEPluginsFromDir('Slave/Providers', "#{$WEACEToolkitDir}/Install/Slave/Providers", 'WEACEInstall::Slave::Providers', false)
      # Slave Adapters
      parseAdapters('Slave', @SlaveAdapters)
      # Slave Listeners
      parseWEACEPluginsFromDir('Slave/Listeners', "#{$WEACEToolkitDir}/Install/Slave/Listeners", 'WEACEInstall::Slave::Listeners')
    end

    # Execute the installer
    #
    # Parameters:
    # * *iParameters* (<em>list<String></em>): Parameters given to the installer
    def execute(iParameters)
      logDebug "> install.rb #{iParameters.join(' ')}"
      @DebugMode = false
      @ForceMode = false
      @ComponentToInstall = nil
      @OutputComponents = false
      @OutputDetails = false
      @OutputVersion = false
      lOptions = getOptions
      if (iParameters.size == 0)
        puts lOptions
      else
        # Parse options
        lInstallerArgs, lAdditionalArgs = splitParameters(iParameters)
        lSuccess = true
        begin
          lOptions.parse(lInstallerArgs)
        rescue Exception
          puts "Error while parsing arguments: #{$!}"
          puts lOptions
          lSuccess = false
        end
        if (lSuccess)
          activateLogDebug(@DebugMode)
          # Execute what was asked by the options
          if (@OutputVersion)
            # Read version info
            lReleaseInfo = {
              :Version => 'Development',
              :Tags => [],
              :DevStatus => 'Unofficial'
            }
            lReleaseInfoFileName = "#{$WEACEToolkitDir}/ReleaseInfo"
            if (File.exists?(lReleaseInfoFileName))
              File.open(lReleaseInfoFileName, 'r') do |iFile|
                lReleaseInfo = eval(iFile.read)
              end
            end
            puts lReleaseInfo[:Version]
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

    private
    
    # Get the installed description of a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # Return:
    # * <em>map<Symbol, Object></em>: The description, or nil if not installed
    def getInstalledComponentDescription(iComponentName)
      rDescription = nil

      lRegisteredFileName = nil
      if (iComponentName.match(/^Master\/.*$/) != nil)
        lRegisteredFileName = "#{$WEACEToolkitDir}/Master/Repository/#{getValidFileName(iComponentName)}.rb"
      else
        lRegisteredFileName = "#{$WEACEToolkitDir}/Slave/Repository/#{getValidFileName(iComponentName)}.rb"
      end
      if (File.exists?(lRegisteredFileName))
        File.open(lRegisteredFileName, 'r') do |iFile|
          rDescription = eval(iFile.read)
        end
      end

      return rDescription
    end

    # Output information of a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # * *iComponentDescription* (<em>map<Symbol,Object></em>): The component description
    def outputComponent(iComponentName, iComponentDescription)
      if (@OutputDetails)
        puts "* Component: #{iComponentName}"
        # TODO: Check if we can use Version
        #puts "  * Version: #{iComponentDescription[:Version]}"
        puts "  * Description: #{iComponentDescription[:Description]}"
        puts "  * Author: #{iComponentDescription[:Author]}"
        # Display info about its installed version
        lInstalledComponentDescription = getInstalledComponentDescription(iComponentName)
        if (lInstalledComponentDescription != nil)
          # TODO: Maybe also use version here ?
          puts "  * Installed on #{lInstalledComponentDescription[:InstallationDate]}"
        else
          puts "  * Not installed"
        end
        if (iComponentDescription[:Options] != nil)
          puts '  * Options:'
          puts iComponentDescription[:Options].summarize
        end
        puts ''
      else
        puts "* #{iComponentName}"
      end
    end

    # Output information of a Provider
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # * *iComponentDescription* (<em>map<Symbol,Object></em>): The component description
    def outputProvider(iComponentName, iComponentDescription)
      if (@OutputDetails)
        puts "* Provider type: #{iComponentName}"
        # TODO: Check if we can use Version
        #puts "  * Version: #{iComponentDescription[:Version]}"
        puts "  * Description: #{iComponentDescription[:Description]}"
        puts "  * Author: #{iComponentDescription[:Author]}"
        if (iComponentDescription[:Options] != nil)
          puts '  * Options:'
          puts iComponentDescription[:Options].summarize
        end
        puts ''
      else
        puts "* #{iComponentName}"
      end
    end

    # Iterate over the components whose name match a given reg exp
    #
    # Parameters:
    # * *iRegExp* (_RegExp_): The filter
    # * *CodeBlock*: The code called for each iteration:
    # ** *iComponentName* (_String_): The component name
    # ** *iCategoryName* (_String_): The corresponding plugin category name
    # ** *iPluginName* (_String_): The corresponding plugin name
    def forEachFilteredComponent(iRegExp)
      @InstallableComponents.each do |iComponentName, iComponentInfo|
        if (iComponentName.match(iRegExp) != nil)
          iCategoryName, iPluginName = iComponentInfo
          yield(iComponentName, iCategoryName, iPluginName)
        end
      end
    end

    # Outputs the list of components
    def outputComponents
      puts ''
      puts '== Installable WEACE Master Server:'
      puts '' if (@OutputDetails)
      forEachFilteredComponent(/^Master\/Server/) do |iComponentName, iCategoryName, iPluginName|
        outputComponent(iComponentName, @PluginsManager.getPluginDescription(iCategoryName, iPluginName))
      end
      puts ''
      puts '== Installable WEACE Master Adapters (please install Server first):'
      puts '' if (@OutputDetails)
      forEachFilteredComponent(/^Master\/Adapters/) do |iComponentName, iCategoryName, iPluginName|
        outputComponent(iComponentName, @PluginsManager.getPluginDescription(iCategoryName, iPluginName))
      end
      puts ''
      puts '== Possible WEACE Master Providers:'
      puts '' if (@OutputDetails)
      @PluginsManager.getPluginsDescriptions('Master/Providers').each do |iPluginName, iPluginDescription|
        outputProvider(iPluginName, iPluginDescription)
      end
      puts ''
      puts '== Installable WEACE Slave Client:'
      puts '' if (@OutputDetails)
      forEachFilteredComponent(/^Slave\/Client/) do |iComponentName, iCategoryName, iPluginName|
        outputComponent(iComponentName, @PluginsManager.getPluginDescription(iCategoryName, iPluginName))
      end
      puts ''
      puts '== Installable WEACE Slave Adapters (please install Client first):'
      puts '' if (@OutputDetails)
      forEachFilteredComponent(/^Slave\/Adapters/) do |iComponentName, iCategoryName, iPluginName|
        outputComponent(iComponentName, @PluginsManager.getPluginDescription(iCategoryName, iPluginName))
      end
      puts ''
      puts '== Installable WEACE Slave Listeners:'
      puts '' if (@OutputDetails)
      forEachFilteredComponent(/^Slave\/Listeners/) do |iComponentName, iCategoryName, iPluginName|
        outputComponent(iComponentName, @PluginsManager.getPluginDescription(iCategoryName, iPluginName))
      end
      puts ''
      puts '== Possible WEACE Slave Providers:'
      puts '' if (@OutputDetails)
      @PluginsManager.getPluginsDescriptions('Slave/Providers').each do |iPluginName, iPluginDescription|
        outputProvider(iPluginName, iPluginDescription)
      end
    end

    # Register a new WEACE Adapter
    #
    # Parameters:
    # * *iRepositoryDir* (_String_): Repository directory
    # * *iComponentName* (_String_): Name of the component to register
    # * *iDescription* (<em>map<Symbol,Object></em>): The plugin description
    # * *iParameters* (<em>list<String></em>): Parameters used when installing this component
    def registerInstalledComponent(iRepositoryDir, iComponentName, iDescription, iParameters)
      lFileName = "#{iRepositoryDir}/#{getValidFileName(iComponentName)}.rb"
      logDebug "Register #{iComponentName} in file #{lFileName} ..."
      # Create the repository if needed
      if (!File.exists?(iRepositoryDir))
        require 'fileutils'
        FileUtils::mkdir_p(iRepositoryDir)
      end
      File.open(lFileName, 'w') do |oFile|
        # TODO: Check if Version can be used here
        oFile << "
{
  :InstallationDate => '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}',
  :Description => '#{iDescription[:Description].gsub(/'/,'\\\\\'')}',
  :Author => '#{iDescription[:Author].gsub(/'/,'\\\\\'')}',
  :InstallationParameters => '#{iParameters.join(' ').gsub(/'/,'\\\\\'')}'
}
"
      end
    end

    # Install a given component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # * *iParameters* (<em>list<String></em>): The list of parameters for this installation
    def installComponent(iComponentName, iParameters)
      logInfo "=== Install Component #{iComponentName} (#{iParameters.inspect}) ..."
      lCategoryName, lPluginName = @InstallableComponents[iComponentName]
      if (lCategoryName == nil)
        logErr "Unknown component name #{iComponentName}. Please use --list option to know installable components."
      else
        lInstalledDescription = getInstalledComponentDescription(iComponentName)
        if ((@ForceMode) or
            (lInstalledDescription == nil))
          # Get a little information on the component being installed
          lIsMaster = (iComponentName.match(/^Master\/.*$/) != nil)
          lIsMasterServer = (iComponentName.match(/^Master\/Server\/.*$/) != nil)
          lIsSlaveClient = (iComponentName.match(/^Slave\/Client\/.*$/) != nil)
          # Forbid installing Adapters and Listeners if Server or Client is not installed.
          lCancel = false
          if ((!lIsMasterServer) and
              (!lIsSlaveClient))
            # We are installing an Adapter or Listener. Check that its Server/Client is installed.
            if (lIsMaster)
              if (!File.exists?("#{$WEACEToolkitDir}/Master/Repository/Master_Server_WEACEMasterServer.rb"))
                logErr "You must first install component Master/Server/WEACEMasterServer before installing #{iComponentName}."
                lCancel = true
              end
            elsif (!File.exists?("#{$WEACEToolkitDir}/Slave/Repository/Slave_Client_WEACESlaveClient.rb"))
              logErr "You must first install component Slave/Client/WEACESlaveClient before installing #{iComponentName}."
              lCancel = true
            end
          end
          if (!lCancel)
            @PluginsManager.accessPlugin(lCategoryName, lPluginName) do |ioPlugin|
              # Get the description to parse options
              lAdditionalArgs = initPluginWithParameters(ioPlugin, iParameters)
              # Always give reference to the plugins manager
              ioPlugin.instance_variable_set(:@PluginsManager, @PluginsManager)
              # Execute the installation for real
              lError = ioPlugin.execute(lAdditionalArgs)
              if (lError == nil)
                # Register this component as being installed
                if (lIsMaster)
                  registerInstalledComponent("#{$WEACEToolkitDir}/Master/Repository", iComponentName, ioPlugin.pluginDescription, iParameters)
                else
                  registerInstalledComponent("#{$WEACEToolkitDir}/Slave/Repository", iComponentName, ioPlugin.pluginDescription, iParameters)
                end
                logMsg "Component #{iComponentName} installed successfully."
              elsif (lError.kind_of?(Exception))
                logExc lError, "An error occurred while installing component #{iComponentName}."
              else
                logBug "Component #{iComponentName} installation returned an error that is not an Exception object: #{lError}"
              end
            end
          end
        else
          # Already installed.
          logErr "Component #{iComponentName} has already been installed on #{lInstalledDescription[:InstallationDate]} with parameters \"#{lInstalledDescription[:InstallationParameters]}\". Use --force option to bypass this check."
        end
      end
    end

    # Loop on all directories containing scripts for a given Adapters directory
    #
    # Parameters:
    # * *iDirectoryType* (_String_): Type of directory to parse (Master/Slave)
    # * _CodeBlock_: The code to be called for each directory containing scripts:
    # ** *iProductID* (_String_): Name of the Product
    # ** *iToolID* (_String_): Name of the Tool
    def eachAdapterDir(iDirectoryType)
      Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectoryType}/Adapters/*").each do |iProductDirName|
        if (File.directory?(iProductDirName))
          lProductID = File.basename(iProductDirName)
          Dir.glob("#{iProductDirName}/*").each do |iToolDirName|
            if (File.directory?(iToolDirName))
              yield(lProductID, File.basename(iToolDirName))
            end
          end
        end
      end
    end

    # Get options of this installer
    #
    # Return:
    # * _OptionParser_: The options parser
    def getOptions
      rOptions = OptionParser.new

      rOptions.banner = 'install.rb [-h|--help] [-v|--version] [-d|--debug] [-l|--list] [-e|--detailedlist] [-i|--install <Component> [-f|--force] -- <AdditionalParameters>]'
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
      rOptions.on('-f', '--force',
        'Force installation of components even if they were already installed.') do
        @ForceMode = true
      end
      rOptions.on('-d', '--debug',
        'Execute the installer in debug mode (more verbose).') do
        @DebugMode = true
      end
      rOptions.on('-l', '--list',
        'Give a list of all components in this distribution.') do
        @OutputComponents = true
      end
      rOptions.on('-e', '--detailedlist',
        'Give a list with details of all components in this distribution.') do
        @OutputComponents = true
        @OutputDetails = true
      end
      rOptions.on('-v', '--version',
        'Get version of this WEACE Toolkit release.') do
        @OutputVersion = true
      end
      rOptions.on('--',
        'Following -- are the parameters specific to the installation of a given component (check each component\'s options with --list).')

      return rOptions
    end

    # Initialize a freshly read plugin description
    # This is used to set additional variables among the description already created by the plugins manager.
    #
    # Parameters:
    # * *ioDescription* (<em>map<Symbol,Object></em>): The description to complete
    def initializePluginDescription(ioDescription)
      if (ioDescription[:VarOptions] != nil)
        ioDescription[:Options] = OptionParser.new
        # The map of mandatory variables, along with their description and value once affected
        # map< Symbol,       [ OptionParser, String ] >
        # map< VariableName, [ Description,  Value  ] >
        ioDescription[:MandatoryVariables] = {}
        ioDescription[:VarOptions].each do |iVarOption|
          iVariable = iVarOption[0]
          iParameters = iVarOption[1..-1]
          # Avoid duplicates
          if (ioDescription[:MandatoryVariables][iVariable] == nil)
            # Create a little OptionParser to format the parameters correctly
            lSingleOption = OptionParser.new
            lSingleOption.on(*iParameters)
            ioDescription[:MandatoryVariables][iVariable] = [ lSingleOption, nil ]
          else
            # Add this option to the variable help: 2 options can define the same variable
            ioDescription[:MandatoryVariables][iVariable][0].on(*iParameters)
          end
          # Set the variable correctly when the option is encountered
          ioDescription[:Options].on(*iParameters) do |iArg|
            ioDescription[:MandatoryVariables][iVariable][1] = iArg
          end
        end
      end
    end

    # Register WEACE plugins read from a directory.
    # This reads the plugins descriptions the same parsePluginsFromDir does, but it completes the description with WEACE specific attributes.
    #
    # Parameters:
    # * *iCategoryName* (_String_): The category name of the plugins
    # * *iDir* (_String_): Directory containing plugins
    # * *iBaseClassName* (_String_): Name of the base class of every plugin in this directory
    # * *iInstallable* (_Boolean_): Are the parsed plugins installable ? [optional = true]
    def parseWEACEPluginsFromDir(iCategoryName, iDir, iBaseClassName, iInstallable = true)
      # Get plugins from there
      @PluginsManager.parsePluginsFromDir(iCategoryName, iDir, iBaseClassName)
      # Create the corresponding OptionsParser object, and complete the current description with it
      @PluginsManager.getPluginsDescriptions(iCategoryName).each do |iScriptID, ioDescription|
        initializePluginDescription(ioDescription)
        if (iInstallable)
          @InstallableComponents["#{iCategoryName}/#{iScriptID}"] = [ iCategoryName, iScriptID ]
        end
      end
    end

    # Fill a map of adapters read from disk
    #
    # Parameters:
    # * *iDirectoryType* (_String_): Type of ditrectory to read (Master/Slave)
    # * *oAdaptersMap* (<em>map<String,map<String,nil>></em>): The map to fill with the Adapters info
    def parseAdapters(iDirectoryType, oAdaptersMap)
      eachAdapterDir(iDirectoryType) do |iProductID, iToolID|
        lCategoryName = "#{iDirectoryType}/Adapters/#{iProductID}/#{iToolID}"
        parseWEACEPluginsFromDir(lCategoryName, "#{$WEACEToolkitDir}/Install/#{iDirectoryType}/Adapters/#{iProductID}/#{iToolID}", "WEACEInstall::#{iDirectoryType}::Adapters::#{iProductID}::#{iToolID}")
        # Register this product/tool category
        if (oAdaptersMap[iProductID] == nil)
          oAdaptersMap[iProductID] = {}
        end
        oAdaptersMap[iProductID][iToolID] = nil
      end
    end

  end

end

# It is possible that we are required by the test framework
if (__FILE__ == $0)
  # Create the installer, and execute it
  WEACEInstall::Installer.new.execute(ARGV)
end