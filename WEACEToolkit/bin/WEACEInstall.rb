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

require 'WEACEToolkit/WEACE_Common'
require 'WEACEToolkit/Install/WEACE_InstallCommon'

module WEACEInstall

  # Main Installer class
  class Installer
  
    include WEACE::Toolbox
    include WEACEInstall::Common

    # Error returned when the plugin's check method did not authorize the installation
    class CheckError < RuntimeError

      # The underlying error returned by the check method
      #   Exception
      attr_reader :CheckError

      # Constructor
      #
      # Parameters:
      # * *iCheckError* (_Exception_): The underlying error
      def initialize(iCheckError)
        super("Checking did not authorize the Component to be installed: #{iCheckError}")
        @CheckError = iCheckError
      end

    end

    # Error raised when a plugin does not have any execute method
    class MissingExecuteError < RuntimeError
    end

    # Error raised when encountering an unknown component
    class UnknownComponentError < RuntimeError
    end

    # Error used to indicate when a Component is already installed
    class AlreadyInstalledComponentError < RuntimeError
    end

    # Error used to indicate that a Master Product is missing
    class MissingMasterProductError < RuntimeError
    end

    # Error used to indicate that a Slave Product is missing
    class MissingSlaveProductError < RuntimeError
    end

    # Error raised when attempting to install components depending on WEACE Master Server
    class MissingWEACEMasterServerError < RuntimeError
    end

    # Error raised when attempting to install components depending on WEACE Slave Client
    class MissingWEACESlaveClientError < RuntimeError
    end

    # Error used to indicate that a Slave Tool is missing
    class MissingSlaveToolError < RuntimeError
    end

    # Constructor
    def initialize

        # Read the directories locations
      lWEACERepositoryDir, @WEACELibDir = getWEACERepositoryDirs
      @WEACEInstallDir = "#{lWEACERepositoryDir}/Install"
      @WEACEConfigDir = "#{lWEACERepositoryDir}/Config"
      @WEACEInstalledComponentsDir = "#{@WEACEInstallDir}/InstalledComponents"

      # Registered installable master and slave adapters
      # map< String,    nil >
      # map< ProductID, nil >
      @MasterAdapters = {}
      # map< String,    map< String, nil > >
      # map< ProductID, map< ToolID, nil > >
      @SlaveAdapters = {}
      # The set of installable components, as written by the user on the command line, and the corresponding plugin
      # map< String, [ String, String ] >
      # map< ComponentFullName, [ iCategoryName, iPluginName ] >
      @InstallableComponents = {}

      # Read plugins
      require 'rUtilAnts/Plugins'
      @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
      parseMasterPlugins
      parseSlavePlugins
    end

    # Execute the installer
    #
    # Parameters:
    # * *iParameters* (<em>list<String></em>): Parameters given to the installer
    # Return:
    # * _Exception_: An error, or nil in case of success
    def execute(iParameters)
      rError = nil

      # Reset variables used in command line parsing
      @DebugMode = false
      @OutputComponents = false
      @OutputDetails = false
      @OutputVersion = false
      @ComponentToInstall = nil
      @ForceMode = false
      @ProviderType = nil
      @ProductID = nil
      @AsProductName = nil
      @ToolID = nil
      @OnProductName = nil
      @ActionID = nil
      @ProcessID = nil
      @ListenerID = nil
      lOptions = getOptions
      if (iParameters.size == 0)
        puts lOptions
        rError = CommandLineError.new('No parameter specified.')
      else
        # Parse options
        lInstallerArgs, lAdditionalArgs = splitParameters(iParameters)
        begin
          lOptions.parse(lInstallerArgs)
        rescue Exception
          puts lOptions
          rError = $!
        end
        if (rError == nil)
          # Store a log file in the Install directory
          require 'fileutils'
          FileUtils::mkdir_p(@WEACEInstallDir)
          FileUtils::mkdir_p(@WEACEConfigDir)
          setLogFile("#{@WEACEInstallDir}/Install.log")
          activateLogDebug(@DebugMode)
          logDebug "> WEACEInstall.rb #{iParameters.join(' ')}"
          logDebug "Install repository: #{@WEACEInstallDir}"
          logDebug "Config repository: #{@WEACEConfigDir}"
          logDebug "Library directory: #{@WEACELibDir}"

          # Execute what was asked by the options
          if (@OutputVersion)
            # Read version info
            lReleaseInfo = {
              :Version => 'Development',
              :Tags => [],
              :DevStatus => 'Unofficial'
            }
            lReleaseInfoFileName = "#{@WEACELibDir}/ReleaseInfo"
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
            # Check that the signature was indeed respected
            case @ComponentToInstall
            when 'SlaveClient'
              if (@ProviderType == nil)
                rError = CommandLineError.new('Please specify a Provider type using --provider option.')
              else
                rError = installSlaveClient(@ProviderType, lAdditionalArgs)
              end
            when 'SlaveProduct'
              if ((@ProductID == nil) or
                  (@AsProductName == nil))
                rError = CommandLineError.new('Please specify a Product and a name using --product and --as options.')
              else
                rError = installSlaveProduct(@ProductID, @AsProductName, lAdditionalArgs)
              end
            when 'SlaveTool'
              if ((@ToolID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Tool and a Product name using --tool and --on options.')
              else
                rError = installSlaveTool(@ToolID, @OnProductName, lAdditionalArgs)
              end
            when 'SlaveAction'
              if ((@ToolID == nil) or
                  (@ActionID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Tool, Action and a Product name using --tool, --action and --on options.')
              else
                rError = installSlaveAction(@ToolID, @ActionID, @OnProductName, lAdditionalArgs)
              end
            when 'SlaveListener'
              if (@ListenerID == nil)
                rError = CommandLineError.new('Please specify a Listener using --listener option.')
              else
                rError = installSlaveListener(@ListenerID, lAdditionalArgs)
              end
            when 'MasterServer'
              if (@ProviderType == nil)
                rError = CommandLineError.new('Please specify a Provider type using --provider option.')
              else
                rError = installMasterServer(@ProviderType, lAdditionalArgs)
              end
            when 'MasterProduct'
              if ((@ProductID == nil) or
                  (@AsProductName == nil))
                rError = CommandLineError.new('Please specify a Product and a name using --product and --as options.')
              else
                rError = installMasterProduct(@ProductID, @AsProductName, lAdditionalArgs)
              end
            when 'MasterProcess'
              if ((@ProcessID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Process and a Product name using --process and --on options.')
              else
                rError = installMasterProcess(@ProcessID, @OnProductName, lAdditionalArgs)
              end
            else
              rError = UnknownComponentError.new("Unknown component to install: #{@ComponentToInstall}")
            end
          end
        end
      end

      return rError
    end

    private
    
    # Parse Master plugins
    def parseMasterPlugins
      # Master Providers
      parseWEACEPluginsFromDir('Master/Providers', "#{@WEACELibDir}/Install/Master/Providers", 'WEACEInstall::Master::Providers', false)
      # Master Server
      parseWEACEPluginsFromDir('Master/Server', "#{@WEACELibDir}/Install/Master/Server", 'WEACEInstall::Master')
      # Master Adapters
      # Master Products
      parseWEACEPluginsFromDir('Master/Products', "#{@WEACELibDir}/Install/Master/Adapters", 'WEACEInstall::Master::Adapters', false)
      Dir.glob("#{@WEACELibDir}/Install/Master/Adapters/*").each do |iProductDirName|
        if (File.directory?(iProductDirName))
          lProductID = File.basename(iProductDirName)
          # Master Processes
          parseWEACEPluginsFromDir("Master/Processes/#{lProductID}", "#{@WEACELibDir}/Install/Master/Adapters/#{lProductID}", "WEACEInstall::Master::Adapters::#{lProductID}")
          # Register this product/tool category
          @MasterAdapters[lProductID] = nil
        end
      end
    end

    # Parse Slave plugins
    def parseSlavePlugins
      # Slave Providers
      parseWEACEPluginsFromDir('Slave/Providers', "#{@WEACELibDir}/Install/Slave/Providers", 'WEACEInstall::Slave::Providers', false)
      # Slave Client
      parseWEACEPluginsFromDir('Slave/Client', "#{@WEACELibDir}/Install/Slave/Client", 'WEACEInstall::Slave')
      # Slave Adapters
      # Slave Products
      parseWEACEPluginsFromDir('Slave/Products', "#{@WEACELibDir}/Install/Slave/Adapters", 'WEACEInstall::Slave::Adapters', false)
      Dir.glob("#{@WEACELibDir}/Install/Slave/Adapters/*").each do |iProductDirName|
        if (File.directory?(iProductDirName))
          lProductID = File.basename(iProductDirName)
          # Slave Tools
          parseWEACEPluginsFromDir("Slave/Tools/#{lProductID}", "#{@WEACELibDir}/Install/Slave/Adapters/#{lProductID}", "WEACEInstall::Slave::Adapters::#{lProductID}", false)
          Dir.glob("#{iProductDirName}/*").each do |iToolDirName|
            if (File.directory?(iToolDirName))
              lToolID = File.basename(iToolDirName)
              # Slave Actions
              parseWEACEPluginsFromDir("Slave/Actions/#{lProductID}/#{lToolID}", "#{@WEACELibDir}/Install/Slave/Adapters/#{lProductID}/#{lToolID}", "WEACEInstall::Slave::Adapters::#{lProductID}::#{lToolID}")
              # Register this product/tool category
              if (@SlaveAdapters[lProductID] == nil)
                @SlaveAdapters[lProductID] = {}
              end
              @SlaveAdapters[lProductID][lToolID] = nil
            end
          end
        end
      end
      # Slave Listeners
      parseWEACEPluginsFromDir('Slave/Listeners', "#{@WEACELibDir}/Install/Slave/Listeners", 'WEACEInstall::Slave::Listeners')
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

    # Generate the default config file for a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Name of the component
    # * *iDefaultConfContent* (_String_): Default configuration
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installer
    def generateConfigFile(iComponentName, iDefaultConfContent, iParameters)
      lConfFileName = getConfigFileName(iComponentName)
      logDebug "Generate configuration file #{lConfFileName} for #{iComponentName} ..."
      # Create the repository if needed
      lDirName = File.dirname(lConfFileName)
      if (!File.exists?(lDirName))
        require 'fileutils'
        FileUtils::mkdir_p(lDirName)
      end
      File.open(lConfFileName, 'w') do |oFile|
        oFile << "\# Configuration file of #{iComponentName}.
\# This file has been generated by WEACEInstall.rb on #{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}.
\# Parameters used for its generation: #{iParameters.join(' ')}
\# Feel free to modify it to accomodate to your configuration.

#{iDefaultConfContent}
"
      end
    end

    # Register a new WEACE component
    #
    # Parameters:
    # * *iComponentName* (_String_): Name of the component to register
    # * *iDescription* (<em>map<Symbol,Object></em>): The plugin description
    # * *iParameters* (<em>list<String></em>): Parameters used when installing this component
    # * *iAdditionalRegistrationInfo* (<em>map<Symbol,String></em>): Additional registration info to add to the installation info [optional = {}]
    def generateInstallFile(iComponentName, iDescription, iParameters, iAdditionalRegistrationInfo)
      lFileName = getInstallFileName(iComponentName)
      logDebug "Generate installation file #{lFileName} for #{iComponentName} ..."
      # Create the repository if needed
      lDirName = File.dirname(lFileName)
      if (!File.exists?(lDirName))
        require 'fileutils'
        FileUtils::mkdir_p(lDirName)
      end
      # Build the map to store in this file
      lInfoToRegister = iAdditionalRegistrationInfo.merge( {
        :InstallationDate => DateTime.now.strftime('%Y-%m-%d %H:%M:%S'),
        :Description => iDescription[:Description],
        :Author => iDescription[:Author],
        :InstallationParameters => iParameters.join(' ')
      } )
      # Build the list of strings to insert in the file
      # list< String >
      lStrInfo = []
      lInfoToRegister.each do |iProperty, iValue|
        lStrInfo << "  :#{iProperty.to_s} => '#{iValue.gsub(/'/,'\\\\\'')}'"
      end
      File.open(lFileName, 'w') do |oFile|
        # TODO: Check if Version can be used here
        oFile << "\# File generated by WEACEInstall on #{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}.
\# !!! DO NOT MODIFY IT as it is used to keep track of what has been installed using WEACE Toolkit.
{
#{lStrInfo.join(",\n")}
}
"
      end
    end

    # Install a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Name of the component to install
    # * *iPluginCategory* (_String_): Plugin category this component belongs to
    # * *iPluginName* (_String_): Plugin name of the component
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # * *iProviderEnv* (<em>map<Symbol,Object></em>): The Provider's environment, or nil if not applicable
    # * *iAdditionalRegistrationInfo* (<em>map<Symbol,String></em>): Additional registration info to add to the installation info [optional = {}]
    # * *iProductConfig* (<em>map<Symbol,String></em>): Corresponding Product's configuration This is used to instantiate @ProductConfig variable in the installation plugin. [optional = nil]
    # * *iToolConfig* (<em>map<Symbol,String></em>): Corresponding Tool's configuration. This is used to instantiate @ToolConfig variable in the installation plugin. [optional = nil]
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installComponent(iComponentName, iPluginCategory, iPluginName, iParameters, iProviderEnv, iAdditionalRegistrationInfo = {}, iProductConfig = nil, iToolConfig = nil)
      rError = nil

      logDebug "Install Component #{iComponentName} from plugin #{iPluginCategory}/#{iPluginName} with parameters \"#{iParameters.join(' ')}\""
      logDebug "Provider environment: #{iProviderEnv.inspect}"
      logDebug "Additional installation info: #{iAdditionalRegistrationInfo.inspect}"
      logDebug "Product configuration: #{iProductConfig.inspect}"
      logDebug "Tool configuration: #{iToolConfig.inspect}"
      # Check that such a component does not exist yet
      lComponentInstallInfo = getInstalledComponentDescription(iComponentName)
      if ((@ForceMode) or
          (lComponentInstallInfo == nil))
        if (lComponentInstallInfo != nil)
          logWarn "Component #{iComponentName} already exists: it has been installed on #{lComponentInstallInfo[:InstallationDate]} with the following parameters: #{lComponentInstallInfo[:InstallationParameters]}. Will force its re-installation."
        end
        @PluginsManager.accessPlugin(iPluginCategory, iPluginName) do |ioPlugin|
          # Get the description to parse options
          rError, lAdditionalArgs = initPluginWithParameters(ioPlugin, iParameters)
          if (rError == nil)
            # Give some references for the plugins to use
            ioPlugin.instance_variable_set(:@PluginsManager, @PluginsManager)
            ioPlugin.instance_variable_set(:@WEACEConfigDir, @WEACEConfigDir)
            ioPlugin.instance_variable_set(:@WEACELibDir, @WEACELibDir)
            ioPlugin.instance_variable_set(:@AdditionalParameters, lAdditionalArgs)
            if (iProviderEnv != nil)
              ioPlugin.instance_variable_set(:@ProviderEnv, iProviderEnv)
            end
            if (iProductConfig != nil)
              ioPlugin.instance_variable_set(:@ProductConfig, iProductConfig)
            end
            if (iToolConfig != nil)
              ioPlugin.instance_variable_set(:@ToolConfig, iToolConfig)
            end
            # Give variables that are part of the installation
            iAdditionalRegistrationInfo.each do |iSymbol, iObject|
              eval("ioPlugin.instance_variable_set(:@#{iSymbol.to_s}, iObject)")
            end
            # First check if the installation is ready to be performed
            if (ioPlugin.respond_to?(:check))
              lCheckError = ioPlugin.check
              if (lCheckError != nil)
                rError = CheckError.new(lCheckError)
              end
            end
            if (rError == nil)
              # Execute the installation for real
              if (ioPlugin.respond_to?(:execute))
                rError = ioPlugin.execute
                if (rError == nil)
                  # Register this component as being installed
                  generateInstallFile(iComponentName, ioPlugin.pluginDescription, iParameters, iAdditionalRegistrationInfo)
                  # Generate its default configuration file
                  lDefaultConfig = "
{
}
"
                  # Check if the config already exists before trying to write it.
                  lConfFileName = getConfigFileName(iComponentName)
                  if (File.exists?(lConfFileName))
                    logWarn "Configuration file #{lConfFileName} already exists. Will not overwrite it."
                  else
                    if (ioPlugin.respond_to?(:getDefaultConfig))
                      lDefaultConfig = ioPlugin.getDefaultConfig
                    end
                    generateConfigFile(iComponentName, lDefaultConfig, iParameters)
                  end
                  logMsg "Component #{iComponentName} installed successfully."
                end
              else
                rError = MissingExecuteError.new("Plugin #{iPluginCategory}/#{iPluginName} does not define any execute method. This plugin is corrupted.")
              end
            end
          end
        end
      else
        rError = AlreadyInstalledComponentError.new("Component #{iComponentName} already exists: it has been installed on #{lComponentInstallInfo[:InstallationDate]} with the following parameters: #{lComponentInstallInfo[:InstallationParameters]}")
      end

      return rError
    end

    # Check that the SlaveClient or MasterServer has been installed, and get the corresponding Provider environment
    #
    # Parameters:
    # * *iType* (_String_): Type of component to check (Master|Slave)
    # * *CodeBlock*: Code called only if the component is installed
    # ** *iProviderEnv* (<em>map<Symbol,Object></em>): The corresponding Provider's environment
    # ** Return:
    # ** _Exception_: An error, or nil in case of success
    # Return:
    # * _Exception_: An error, or nil in case of success
    def checkInstalledServerClient(iType)
      rError = nil

      lComponentName = nil
      lErrorClass = nil
      if (iType == 'Master')
        lComponentName = 'MasterServer'
        lErrorClass = MissingWEACEMasterServerError
      else
        lComponentName = 'SlaveClient'
        lErrorClass = MissingWEACESlaveClientError
      end
      # First, check that SlaveClient is installed
      lSlaveClientInstallInfo = getInstalledComponentDescription(lComponentName)
      if (lSlaveClientInstallInfo != nil)
        # Read the Slave Provider config
        rError, lProviderEnv = getProviderEnv(iType, lSlaveClientInstallInfo[:ProviderID], lSlaveClientInstallInfo[:InstallationParameters].split(' '))
        if (rError == nil)
          rError = yield(lProviderEnv)
        end
      else
        rError = lErrorClass.new("You must first install component #{lComponentName} before installing other #{iType} Components.")
      end

      return rError
    end

    # Check that a given Product has been installed, and get the corresponding Product ID
    #
    # Parameters:
    # * *iType* (_String_): Type of component to check (Master|Slave)
    # * *iProductName* (_String_): Name of the Product to check
    # * *CodeBlock*: Code called only if the component is installed
    # ** *iProviderEnv* (<em>map<Symbol,Object></em>): The corresponding Provider's environment
    # ** *iProductID* (_String_): The corresponding Product ID
    # ** Return:
    # ** _Exception_: An error, or nil in case of success
    # Return:
    # * _Exception_: An error, or nil in case of success
    def checkInstalledProduct(iType, iProductName)
      return checkInstalledServerClient(iType) do |iProviderEnv|
        lError = nil

        # Then, check that the Product is installed
        lProductInstallInfo = getInstalledComponentDescription(iProductName)
        if (lProductInstallInfo != nil)
          lError = yield(iProviderEnv, lProductInstallInfo[:Product])
        else
          if (iType == 'Master')
            lError = MissingMasterProductError.new("You must first install a #{iType} Product as #{iProductName} before installing any Tool on this #{iType} Product.")
          else
            lError = MissingSlaveProductError.new("You must first install a #{iType} Product as #{iProductName} before installing any Tool on this #{iType} Product.")
          end
        end

        next lError
      end
    end

    # Install the MasterServer
    #
    # Parameters:
    # * *iProviderType* (_String_): The Provider Type
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # *_Exception_: An error, or nil in case of success
    def installMasterServer(iProviderType, iParameters)
      return installComponent(
        'MasterServer',
        'Master/Server',
        'WEACEMasterServer',
        # Options are to be given to the Provider, not the MasterServer installer. So add a -- in front of them.
        ['--'] + iParameters,
        nil,
        {
          :ProviderID => iProviderType
        }
      )
    end

    # Install a Master Product
    #
    # Parameters:
    # * *iProductID* (_String_): The Product ID
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installMasterProduct(iProductID, iProductName, iParameters)
      return checkInstalledServerClient('Master') do |iProviderEnv|
        next installComponent(
          iProductName,
          'Master/Products',
          iProductID,
          iParameters,
          iProviderEnv,
          {
            :Type => 'Master',
            :Product => iProductID
          }
        )
      end
    end

    # Install a Master Process
    #
    # Parameters:
    # * *iProcessID* (_String_): The Process to install
    # * *iProductName* (_String_): The Product on which we install the Process
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installMasterProcess(iProcessID, iProductName, iParameters)
      return checkInstalledProduct('Master', iProductName) do |iProviderEnv, iProductID|
        lProductConfig = getInstalledComponentConfiguration(iProductName)
        next installComponent(
          "#{iProductName}.#{iProcessID}",
          "Master/Processes/#{iProductID}",
          iProcessID,
          iParameters,
          iProviderEnv,
          {},
          lProductConfig
        )
      end
    end

    # Install the SlaveClient
    #
    # Parameters:
    # * *iProviderType* (_String_): The Provider Type
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # *_Exception_: An error, or nil in case of success
    def installSlaveClient(iProviderType, iParameters)
      return installComponent(
        'SlaveClient',
        'Slave/Client',
        'WEACESlaveClient',
        # Options are to be given to the Provider, not the SlaveClient installer. So add a -- in front of them.
        ['--'] + iParameters,
        nil,
        {
          :ProviderID => iProviderType
        }
      )
    end

    # Install a Slave Product
    #
    # Parameters:
    # * *iProductID* (_String_): The Product ID
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installSlaveProduct(iProductID, iProductName, iParameters)
      return checkInstalledServerClient('Slave') do |iProviderEnv|
        next installComponent(
          iProductName,
          'Slave/Products',
          iProductID,
          iParameters,
          iProviderEnv,
          {
            :Type => 'Slave',
            :Product => iProductID
          }
        )
      end
    end

    # Install a Slave Tool
    #
    # Parameters:
    # * *iToolID* (_String_): Name of the Tool to install
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installSlaveTool(iToolID, iProductName, iParameters)
      return checkInstalledProduct('Slave', iProductName) do |iProviderEnv, iProductID|
        lProductConfig = getInstalledComponentConfiguration(iProductName)
        next installComponent(
          "#{iProductName}.#{iToolID}",
          "Slave/Tools/#{iProductID}",
          iToolID,
          iParameters,
          iProviderEnv,
          {},
          lProductConfig
        )
      end
    end

    # Install a Slave Action
    #
    # Parameters:
    # * *iToolID* (_String_): The Tool for which we install the Action
    # * *iActionID* (_String_): The Action we want to install
    # * *iProductName* (_String_): The Product on which we install the Action
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installSlaveAction(iToolID, iActionID, iProductName, iParameters)
      return checkInstalledProduct('Slave', iProductName) do |iProviderEnv, iProductID|
        lError = nil

        lProductConfig = getInstalledComponentConfiguration(iProductName)
        lToolConfig = getInstalledComponentConfiguration("#{iProductName}.#{iToolID}")
        # Then, check that the Tool is installed
        lComponentName = "#{iProductName}.#{iToolID}"
        lToolInstallInfo = getInstalledComponentDescription(lComponentName)
        if (lToolInstallInfo != nil)
          lError = installComponent(
            "#{iProductName}.#{iToolID}.#{iActionID}",
            "Slave/Actions/#{iProductID}/#{iToolID}",
            iActionID,
            iParameters,
            iProviderEnv,
            {},
            lProductConfig,
            lToolConfig
          )
        else
          lError = MissingSlaveToolError.new("You must first install the Tool #{iToolID} on the Slave Product #{iProductName} before installing any Action for this Tool.")
        end

        next lError
      end
    end

    # Install a Slave Listener
    #
    # Parameters:
    # * *iListenerID* (_String_): The Listener ID
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return:
    # * _Exception_: An error, or nil in case of success
    def installSlaveListener(iListenerID, iParameters)
      return checkInstalledServerClient('Slave') do |iProviderEnv|
        next installComponent(
          iListenerID,
          'Slave/Listeners',
          iListenerID,
          iParameters,
          iProviderEnv
        )
      end
    end

    # Get options of this installer
    #
    # Return:
    # * _OptionParser_: The options parser
    def getOptions
      rOptions = OptionParser.new

        rOptions.banner = 'install.rb [-h|--help] [-v|--version] [-d|--debug] [-l|--list] [-e|--detailedlist] [-i|--install <Component> [-f|--force] <InstallParameters> -- <ComponentParameters>]

<InstallParameters> depends on <Component>. Here are the following signatures for each possible value of <Component>:
* SlaveClient => -p|--provider <SlaveProviderType>
* SlaveProduct => -r|--product <ProductID> -s|--as <ProductName>
* SlaveTool => -t|--tool <ToolID> -o|--on <ProductName>
* SlaveAction => -t|--tool <ToolID> -a|--action <ActionID> -o|--on <ProductName>
* SlaveListener => -n|--listener <ListenerID>
* MasterServer => -p|--provider <MasterProviderType>
* MasterProduct => -r|--product <ProductID> -s|--as <ProductName>
* MasterProcess => -c|--process <ProcessID> -o|--on <ProductName>

<ComponentParameters> depends on each different component being installed. Please use --detailedlist to know their signatures.

'
      # Options are defined here
      rOptions.on('-h', '--help',
        'Display help on this script.') do
        puts rOptions
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
      rOptions.on('-i', '--install <Component>', String,
        '<Component>: One of the following values: SlaveClient, SlaveProduct, SlaveTool, SlaveAction, MasterServer, MasterProduct, MasterProcess.',
        'Install a given component.') do |iArg|
        @ComponentToInstall = iArg
      end
      rOptions.on('-f', '--force',
        'Force installation of components even if they were already installed.') do
        @ForceMode = true
      end
      rOptions.on('-p', '--provider <ProviderType>', String,
        '<ProviderType>: One of the possible Provider types available. Please use --detailedlist to know possible values.',
        'Specify the Provider to install the SlaveClient or MasterServer.') do |iArg|
        @ProviderType = iArg
      end
      rOptions.on('-r', '--product <ProductID>', String,
        '<ProductID>: One of the possible Products available. Please use --detailedlist to know possible values.',
        'Specify the Product to install.') do |iArg|
        @ProductID = iArg
      end
      rOptions.on('-s', '--as <ProductName>', String,
        '<ProductName>: Alias to give the Product\'s installation. This alias will then be used to install further Adapters on this Product.',
        'Specify the name of this Product\'s installation to be referenced later.') do |iArg|
        @AsProductName = iArg
      end
      rOptions.on('-t', '--tool <ToolID>', String,
        '<ToolID>: One of the possible Tools available. Please use --detailedlist to know possible values.',
        'Specify the Tool on which this installation will apply.') do |iArg|
        @ToolID = iArg
      end
      rOptions.on('-o', '--on <ProductName>', String,
        '<ProductName>: Alias given previously to a Product\'s installation.',
        'Specify on which Product the installation applies.') do |iArg|
        @OnProductName = iArg
      end
      rOptions.on('-a', '--action <ActionID>', String,
        '<ActionID>: One of the possible Actions available. Please use --detailedlist to know possible values.',
        'Specify which Action to install on the given Product/Tool.') do |iArg|
        @ActionID = iArg
      end
      rOptions.on('-c', '--process <ProcessID>', String,
        '<ProcessID>: One of the possible Master Processes available. Please use --detailedlist to know possible values.',
        'Specify which Process to install on the given Product.') do |iArg|
        @ProcessID = iArg
      end
      rOptions.on('-n', '--listener <ListenerID>', String,
        '<ListenerID>: One of the possible Slave Listeners available. Please use --detailedlist to know possible values.',
        'Specify which Listener to install.') do |iArg|
        @ListenerID = iArg
      end
      rOptions.on('--',
        'Following -- are the parameters specific to the installation of a given component (check each component\'s options with --detailedlist).')

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

  end

end

# It is possible that we are required by the test framework
if (__FILE__ == $0)
  # Initialize logging
  require 'rUtilAnts/Logging'
  RUtilAnts::Logging::initializeLogging(File.expand_path("#{File.dirname(__FILE__)}/.."), 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
  # Create the installer, and execute it
  lError = WEACEInstall::Installer.new.execute(ARGV)
  if (lError == nil)
    exit 0
  else
    logErr "An error occurred: #{lError}."
    exit 1
  end
end
