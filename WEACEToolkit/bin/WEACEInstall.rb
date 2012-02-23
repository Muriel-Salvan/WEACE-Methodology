#!/usr/bin/env ruby
#
# Provide an easy-to-use installation script that can install every WEACE Toolkit component available in this distribution.
# Usage: install.rb --help
#
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'optparse'

require 'rUtilAnts/Misc'
RUtilAnts::Misc::install_misc_on_object
require 'rUtilAnts/Platform'
RUtilAnts::Platform::install_platform_on_object

require 'WEACEToolkit/Common'
require 'WEACEToolkit/Install/Common'

module WEACEInstall

  # Main Installer class
  class Installer
  
    include WEACE::Common
    include WEACEInstall::Common

    # Error returned when the plugin's check method did not authorize the installation
    class CheckError < RuntimeError

      # The underlying error returned by the check method
      #   Exception
      attr_reader :CheckError

      # Constructor
      #
      # Parameters::
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
      setupWEACEDirs
      # Read plugins
      setupInstallPlugins
    end

    # Execute the installer
    #
    # Parameters::
    # * *iParameters* (<em>list<String></em>): Parameters given to the installer
    # Return::
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
          lRemainingInstallArgs = lOptions.parse(lInstallerArgs)
          # Normally, no argument should remain
          if (!lRemainingInstallArgs.empty?)
            rError = CommandLineError.new("Invalid arguments remaining: #{lRemainingInstallArgs.join(' ')}")
          end
        rescue Exception
          puts lOptions
          rError = $!
        end
        if (rError == nil)
          # Store a log file in the Install directory
          require 'fileutils'
          FileUtils::mkdir_p(@WEACEInstallDir)
          FileUtils::mkdir_p(@WEACEConfigDir)
          set_log_file("#{@WEACEInstallDir}/Install.log")
          activate_log_debug(@DebugMode)
          log_debug "> WEACEInstall.rb #{iParameters.join(' ')}"
          log_debug "Install repository: #{@WEACEInstallDir}"
          log_debug "Config repository: #{@WEACEConfigDir}"
          log_debug "Library directory: #{@WEACELibDir}"

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
              elsif ((@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@OnProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Provider type using --provider option.')
              else
                rError = installSlaveClient(@ProviderType, lAdditionalArgs)
              end
            when 'SlaveProduct'
              if ((@ProductID == nil) or
                  (@AsProductName == nil))
                rError = CommandLineError.new('Please specify a Product and a name using --product and --as options.')
              elsif ((@ProviderType != nil) or
                     (@OnProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Product and its name using --product and --as options.')
              else
                rError = installSlaveProduct(@ProductID, @AsProductName, lAdditionalArgs)
              end
            when 'SlaveTool'
              if ((@ToolID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Tool and a Product name using --tool and --on options.')
              elsif ((@ProviderType != nil) or
                     (@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Tool and Product name using --tool and --on options.')
              else
                rError = installSlaveTool(@ToolID, @OnProductName, lAdditionalArgs)
              end
            when 'SlaveAction'
              if ((@ToolID == nil) or
                  (@ActionID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Tool, Action and a Product name using --tool, --action and --on options.')
              elsif ((@ProviderType != nil) or
                     (@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Tool, Action and Product name using --tool, --action and --on options.')
              else
                rError = installSlaveAction(@ToolID, @ActionID, @OnProductName, lAdditionalArgs)
              end
            when 'SlaveListener'
              if (@ListenerID == nil)
                rError = CommandLineError.new('Please specify a Listener using --listener option.')
              elsif ((@ProviderType != nil) or
                     (@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@OnProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Listener using --listener option.')
              else
                rError = installSlaveListener(@ListenerID, lAdditionalArgs)
              end
            when 'MasterServer'
              if (@ProviderType == nil)
                rError = CommandLineError.new('Please specify a Provider type using --provider option.')
              elsif ((@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@OnProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Provider type using --provider option.')
              else
                rError = installMasterServer(@ProviderType, lAdditionalArgs)
              end
            when 'MasterProduct'
              if ((@ProductID == nil) or
                  (@AsProductName == nil))
                rError = CommandLineError.new('Please specify a Product and a name using --product and --as options.')
              elsif ((@ProviderType != nil) or
                     (@OnProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil) or
                     (@ProcessID != nil))
                rError = CommandLineError.new('Please specify only the Product and its name using --product and --as options.')
              else
                rError = installMasterProduct(@ProductID, @AsProductName, lAdditionalArgs)
              end
            when 'MasterProcess'
              if ((@ProcessID == nil) or
                  (@OnProductName == nil))
                rError = CommandLineError.new('Please specify a Process and a Product name using --process and --on options.')
              elsif ((@ProviderType != nil) or
                     (@ProductID != nil) or
                     (@AsProductName != nil) or
                     (@ToolID != nil) or
                     (@ActionID != nil) or
                     (@ListenerID != nil))
                rError = CommandLineError.new('Please specify only the Process and Product name using --process and --on options.')
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
    
    # Display several lines of text given a prefix to apply to every line and a maximal width to respect.
    # Lines longer than maximal width will be split on to next line.
    # The maximal width is taken from @MaxPFWidth.
    #
    # Parameters::
    # * *iPrefix* (_String_): The prefix to apply to every line printed
    # * *iMessage* (_String_): The message to display (can be several lines)
    def pf(iPrefix, iMessage)
      lMaxLineSize = @MaxPFWidth - iPrefix.size
      # Check if the terminal is not too small
      if (lMaxLineSize > 0)
        # Split the message in as many lines as needed.
        lLstLines = []
        iMessage.split("\n").each do |iLine|
          if (iLine.size > lMaxLineSize)
            lRemainingLine = iLine.clone
            while ((lRemainingLine != nil) and
                   (!lRemainingLine.empty?))
              lLstLines << lRemainingLine[0..lMaxLineSize-1]
              lRemainingLine = lRemainingLine[lMaxLineSize..-1]
            end
          else
            lLstLines << iLine
          end
        end
        # Now we dump each line with the prefix
        lLstLines.each do |iLine|
          puts "#{iPrefix}#{iLine}"
        end
      else
        # Terminal too small. Don't try anything: just put as we can.
        puts "#{iPrefix}#{iMessage}"
      end
    end

    # Output a Component's information
    #
    # Parameters::
    # * *iPrefix* (_String_): Prefix to add to each line output
    # * *iComponentInfo* (<em>map<Symbol,Object></em>): The component description
    # * *iExamplePrefix* (_String_): The example command line prefix
    def pfComponent(iPrefix, iComponentInfo, iExamplePrefix)
      if (@OutputDetails)
        pf iPrefix, "Signature: #{iComponentInfo[:Options].to_s}"
        if (iComponentInfo[:OptionsExample] == nil)
          pf iPrefix, "Example: WEACEInstall.rb --install #{iExamplePrefix}"
        else
          pf iPrefix, "Example: WEACEInstall.rb --install #{iExamplePrefix} -- #{iComponentInfo[:OptionsExample]}"
        end
      end
    end

    # Outputs the list of components
    def outputComponents
      # Set the maximal width for pf
      @MaxPFWidth = WEACE::TerminalSize::terminal_size[0]-1

      # Dump Slave info
      # Get the installation info of the SlaveClient
      lSlaveClientInstallInfo = getComponentInstallInfo('SlaveClient')
      pf '', ''
      pf '', '==== << Slave Components >> ===='
      pf '', '|'
      pf '', '+=== << SlaveClient >> ==='
      if (@OutputDetails)
        pf '| ', 'Signature: --install SlaveClient --provider <SlaveProviderType> -- <ProviderParameters>'
        pf '| ', 'Example: WEACEInstall.rb --install SlaveClient --provider SourceForge -- --project myproject'
      end
      if (lSlaveClientInstallInfo == nil)
        pf '| ','Not installed'
      else
        pf '| ', "Installed on #{lSlaveClientInstallInfo[:InstallationDate]} as a Provider of type #{lSlaveClientInstallInfo[:ProviderID]} with parameters \"#{lSlaveClientInstallInfo[:InstallationParameters]}\""
        if (@OutputDetails)
          pf '| ', "Configuration file: #{getConfigFileName('SlaveClient')}"
        end
      end
      pf '', '|'
      pf '', '|'
      # Get the list of Slave Providers
      lSlaveProviders = @PluginsManager.get_plugins_descriptions('Slave/Providers')
      pf '', "+=== << #{lSlaveProviders.size} possible Slave Providers >> ==="
      lIdx = 0
      lSlaveProviders.each do |iProviderID, iInfo|
        pf '| ', '|'
        pf '| ', "+=== << #{iProviderID} >> ==="
        lSubPrefix = nil
        if (lIdx == lSlaveProviders.size-1)
          lSubPrefix = '|   '
        else
          lSubPrefix = '| | '
        end
        pfComponent(lSubPrefix, iInfo, "SlaveClient --provider #{iProviderID}")
        lIdx += 1
      end
      pf '', '|'
      pf '', '|'
      # Get the list of installable Slave Products
      lSlaveProducts = @PluginsManager.get_plugins_descriptions('Slave/Products')
      pf '', "+=== << #{lSlaveProducts.size} installable Slave Products >> ==="
      lIdxProduct = 0
      lSlaveProducts.each do |iProductID, iProductInfo|
        pf '| ', '|'
        pf '| ', "+=== [P] << #{iProductID} >> ==="
        lProductPrefix = nil
        if (lIdxProduct == lSlaveProducts.size-1)
          lProductPrefix = '|   '
        else
          lProductPrefix = '| | '
        end
        pfComponent(lProductPrefix, iProductInfo, "SlaveProduct --product #{iProductID} --as MyProduct")
        # Get the list of Slave Tools
        lSlaveTools = @PluginsManager.get_plugins_descriptions("Slave/Tools/#{iProductID}")
        pf lProductPrefix, "#{lSlaveTools.size} installable Slave Tools for #{iProductID}:"
        lIdxTool = 0
        lSlaveTools.each do |iToolID, iToolInfo|
          pf lProductPrefix, '|'
          pf lProductPrefix, "+=== [T] << #{iToolID} >> ==="
          lToolPrefix = nil
          if (lIdxTool == lSlaveTools.size-1)
            lToolPrefix = "#{lProductPrefix}  "
          else
            lToolPrefix = "#{lProductPrefix}| "
          end
          pfComponent(lToolPrefix, iToolInfo, "SlaveTool --on MyProduct --tool #{iToolID}")
          # Get the list of Slave Actions
          lSlaveActions = @PluginsManager.get_plugins_descriptions("Slave/Actions/#{iProductID}/#{iToolID}")
          pf lToolPrefix, "#{lSlaveActions.size} installable Slave Actions for #{iProductID}/#{iToolID}:"
          lIdxAction = 0
          lSlaveActions.each do |iActionID, iActionInfo|
            pf lToolPrefix, '|'
            pf lToolPrefix, "+=== [A] << #{iActionID} >> ==="
            lActionPrefix = nil
            if (lIdxAction == lSlaveActions.size-1)
              lActionPrefix = "#{lToolPrefix}  "
            else
              lActionPrefix = "#{lToolPrefix}| "
            end
            pfComponent(lActionPrefix, iActionInfo, "SlaveAction --on MyProduct --tool #{iToolID} --action #{iActionID}")
            lIdxAction += 1
          end
          lIdxTool += 1
        end
        lIdxProduct += 1
      end
      pf '', '|'
      pf '', '|'
      # Get the list of installed Slave Products
      lInstalledSlaveProducts = getInstalledSlaveProducts
      pf '', "+=== << #{lInstalledSlaveProducts.size} installed Slave Products >> ==="
      lIdxProduct = 0
      lInstalledSlaveProducts.each do |iProductName, iProductInfo|
        iProductInstallInfo, iTools = iProductInfo
        pf '| ', '|'
        pf '| ', "+=== [P] << #{iProductName} >> (#{iProductInstallInfo[:Product]}) ==="
        lProductPrefix = nil
        if (lIdxProduct == lInstalledSlaveProducts.size-1)
          lProductPrefix = '|   '
        else
          lProductPrefix = '| | '
        end
        pf lProductPrefix, "Installed on #{iProductInstallInfo[:InstallationDate]} with parameters \"#{iProductInstallInfo[:InstallationParameters]}\""
        if (@OutputDetails)
          pf lProductPrefix, "Configuration file: #{getConfigFileName(iProductName)}"
        end
        # Display installed Tools on this Product
        pf lProductPrefix, "#{iTools.size} installed Slave Tools for #{iProductName}"
        lIdxTool = 0
        iTools.each do |iToolID, iToolInfo|
          iToolInstallInfo, iActions = iToolInfo
          pf lProductPrefix, '|'
          pf lProductPrefix, "+=== [T] << #{iToolID} >> ==="
          lToolPrefix = nil
          if (lIdxTool == iTools.size-1)
            lToolPrefix = "#{lProductPrefix}  "
          else
            lToolPrefix = "#{lProductPrefix}| "
          end
          pf lToolPrefix, "Installed on #{iToolInstallInfo[:InstallationDate]} with parameters \"#{iToolInstallInfo[:InstallationParameters]}\""
          if (@OutputDetails)
            pf lToolPrefix, "Configuration file: #{getConfigFileName("#{iProductName}.#{iToolID}")}"
          end
          # Display installed Actions on this Tool
          pf lToolPrefix, "#{iActions.size} installed Slave Actions for #{iProductName}/#{iToolID}"
          lIdxAction = 0
          iActions.each do |iActionID, iActionInfo|
            iActionInstallInfo, iActive = iActionInfo
            pf lToolPrefix, '|'
            lStrActive = nil
            if (iActive)
              lStrActive = 'Active'
            else
              lStrActive = 'Inactive'
            end
            pf lToolPrefix, "+=== [A] << #{iActionID} >> (#{lStrActive}) ==="
            lActionPrefix = nil
            if (lIdxAction == iActions.size-1)
              lActionPrefix = "#{lToolPrefix}  "
            else
              lActionPrefix = "#{lToolPrefix}| "
            end
            pf lActionPrefix, "Installed on #{iActionInstallInfo[:InstallationDate]} with parameters \"#{iActionInstallInfo[:InstallationParameters]}\""
            if (@OutputDetails)
              pf lActionPrefix, "Configuration file: #{getConfigFileName("#{iProductName}.#{iToolID}.#{iActionID}")}"
            end
            lIdxAction += 1
          end
          lIdxTool += 1
        end
        lIdxProduct += 1
      end
      pf '', '|'
      pf '', '|'
      # Get the list of Slave Listeners
      lSlaveListeners = @PluginsManager.get_plugins_descriptions('Slave/Listeners')
      pf '', "+=== << #{lSlaveListeners.size} Slave Listeners >> ==="
      lIdxListener = 0
      lSlaveListeners.each do |iListenerID, iListenerInfo|
        pf '  ', '|'
        pf '  ', "+=== [L] << #{iListenerID} >> ==="
        lListenerPrefix = nil
        if (lIdxListener == lSlaveListeners.size-1)
          lListenerPrefix = '    '
        else
          lListenerPrefix = '  | '
        end
        pfComponent(lListenerPrefix, iListenerInfo, "SlaveListener --listener #{iListenerID}")
        # Get the install information
        lListenerInstallInfo = getComponentInstallInfo(iListenerID)
        if (lListenerInstallInfo == nil)
          pf lListenerPrefix,'Not installed'
        else
          pf lListenerPrefix, "Installed on #{lListenerInstallInfo[:InstallationDate]} with parameters \"#{lListenerInstallInfo[:InstallationParameters]}\""
          if (@OutputDetails)
            pf lListenerPrefix, "Configuration file: #{getConfigFileName(iListenerID)}"
          end
        end
        lIdxListener += 1
      end
      puts ''
      puts ''
      # Dump Master info
      # Get the installation info of the SlaveClient
      lMasterServerInstallInfo = getComponentInstallInfo('MasterServer')
      pf '', ''
      pf '', '==== << Master Components >> ===='
      pf '', '|'
      pf '', '+=== << MasterServer >> ==='
      if (@OutputDetails)
        pf '| ', 'Signature: --install MasterServer --provider <MasterProviderType> -- <ProviderParameters>'
        pf '| ', 'Example: WEACEInstall.rb --install MasterServer --provider SourceForge -- --project myproject'
      end
      if (lMasterServerInstallInfo == nil)
        pf '| ','Not installed'
      else
        pf '| ', "Installed on #{lMasterServerInstallInfo[:InstallationDate]} as a Provider of type #{lMasterServerInstallInfo[:ProviderID]} with parameters \"#{lMasterServerInstallInfo[:InstallationParameters]}\""
        if (@OutputDetails)
          pf '| ', "Configuration file: #{getConfigFileName('MasterServer')}"
        end
      end
      pf '', '|'
      pf '', '|'
      # Get the list of Master Providers
      lMasterProviders = @PluginsManager.get_plugins_descriptions('Master/Providers')
      pf '', "+=== << #{lMasterProviders.size} possible Master Providers >> ==="
      lIdx = 0
      lMasterProviders.each do |iProviderID, iInfo|
        pf '| ', '|'
        pf '| ', "+=== << #{iProviderID} >> ==="
        lSubPrefix = nil
        if (lIdx == lMasterProviders.size-1)
          lSubPrefix = '|   '
        else
          lSubPrefix = '| | '
        end
        pfComponent(lSubPrefix, iInfo, "MasterServer --provider #{iProviderID}")
        lIdx += 1
      end
      pf '', '|'
      pf '', '|'
      # Get the list of installable Master Products
      lMasterProducts = @PluginsManager.get_plugins_descriptions('Master/Products')
      pf '', "+=== << #{lMasterProducts.size} installable Master Products >> ==="
      lIdxProduct = 0
      lMasterProducts.each do |iProductID, iProductInfo|
        pf '| ', '|'
        pf '| ', "+=== [P] << #{iProductID} >> ==="
        lProductPrefix = nil
        if (lIdxProduct == lMasterProducts.size-1)
          lProductPrefix = '|   '
        else
          lProductPrefix = '| | '
        end
        pfComponent(lProductPrefix, iProductInfo, "MasterProduct --product #{iProductID} --as MyProduct")
        # Get the list of Master Processes
        lMasterProcesses = @PluginsManager.get_plugins_descriptions("Master/Processes/#{iProductID}")
        pf lProductPrefix, "#{lMasterProcesses.size} installable Master Processes for #{iProductID}:"
        lIdxProcess = 0
        lMasterProcesses.each do |iProcessID, iProcessInfo|
          pf lProductPrefix, '|'
          pf lProductPrefix, "+=== [C] << #{iProcessID} >> ==="
          lProcessPrefix = nil
          if (lIdxProcess == lMasterProcesses.size-1)
            lProcessPrefix = "#{lProductPrefix}  "
          else
            lProcessPrefix = "#{lProductPrefix}| "
          end
          pfComponent(lProcessPrefix, iProcessInfo, "SlaveProcess --on MyProduct --process #{iProcessID}")
          lIdxProcess += 1
        end
        lIdxProduct += 1
      end
      pf '', '|'
      pf '', '|'
      # Get the list of installed Master Products
      lInstalledMasterProducts = getInstalledMasterProducts
      pf '', "+=== << #{lInstalledMasterProducts.size} installed Master Products >> ==="
      lIdxProduct = 0
      lInstalledMasterProducts.each do |iProductName, iProductInfo|
        iProductInstallInfo, iProcesses = iProductInfo
        pf '| ', '|'
        pf '| ', "+=== [P] << #{iProductName} >> (#{iProductInstallInfo[:Product]}) ==="
        lProductPrefix = nil
        if (lIdxProduct == lInstalledMasterProducts.size-1)
          lProductPrefix = '|   '
        else
          lProductPrefix = '| | '
        end
        pf lProductPrefix, "Installed on #{iProductInstallInfo[:InstallationDate]} with parameters \"#{iProductInstallInfo[:InstallationParameters]}\""
        if (@OutputDetails)
          pf lProductPrefix, "Configuration file: #{getConfigFileName(iProductName)}"
        end
        # Display installed Processes on this Product
        pf lProductPrefix, "#{iProcesses.size} installed Master Processes for #{iProductName}"
        lIdxProcess = 0
        iProcesss.each do |iProcessID, iProcessInstallInfo|
          pf lProductPrefix, '|'
          pf lProductPrefix, "+=== [C] << #{iProcessID} >> ==="
          lProcessPrefix = nil
          if (lIdxProcess == iProcesses.size-1)
            lProcessPrefix = "#{lProductPrefix}  "
          else
            lProcessPrefix = "#{lProductPrefix}| "
          end
          pf lProcessPrefix, "Installed on #{iProcessInstallInfo[:InstallationDate]} with parameters \"#{iProcessInstallInfo[:InstallationParameters]}\""
          if (@OutputDetails)
            pf lProcessPrefix, "Configuration file: #{getConfigFileName("#{iProductName}.#{iProcessID}")}"
          end
          lIdxProcess += 1
        end
        lIdxProduct += 1
      end
    end

    # Generate the default config file for a component
    #
    # Parameters::
    # * *iComponentName* (_String_): Name of the component
    # * *iDefaultConfContent* (_String_): Default configuration
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installer
    def generateConfigFile(iComponentName, iDefaultConfContent, iParameters)
      lConfFileName = getConfigFileName(iComponentName)
      log_debug "Generate configuration file #{lConfFileName} for #{iComponentName} ..."
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
    # Parameters::
    # * *iComponentName* (_String_): Name of the component to register
    # * *iDescription* (<em>map<Symbol,Object></em>): The plugin description
    # * *iParameters* (<em>list<String></em>): Parameters used when installing this component
    # * *iAdditionalRegistrationInfo* (<em>map<Symbol,String></em>): Additional registration info to add to the installation info [optional = {}]
    def generateInstallFile(iComponentName, iDescription, iParameters, iAdditionalRegistrationInfo)
      lFileName = getInstallFileName(iComponentName)
      log_debug "Generate installation file #{lFileName} for #{iComponentName} ..."
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
    # Parameters::
    # * *iComponentName* (_String_): Name of the component to install
    # * *iPluginCategory* (_String_): Plugin category this component belongs to
    # * *iPluginName* (_String_): Plugin name of the component
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # * *iExtraParametersAllowed* (_Boolean_): Are extra parameters allowed ? If true, extra parameters will be given to the @AdditionalParameters plugin variable, separated with '--'.
    # * *iProviderEnv* (<em>map<Symbol,Object></em>): The Provider's environment, or nil if not applicable
    # * *iAdditionalRegistrationInfo* (<em>map<Symbol,String></em>): Additional registration info to add to the installation info [optional = {}]
    # * *iProductConfig* (<em>map<Symbol,String></em>): Corresponding Product's configuration This is used to instantiate @ProductConfig variable in the installation plugin. [optional = nil]
    # * *iToolConfig* (<em>map<Symbol,String></em>): Corresponding Tool's configuration. This is used to instantiate @ToolConfig variable in the installation plugin. [optional = nil]
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installComponent(iComponentName, iPluginCategory, iPluginName, iParameters, iExtraParametersAllowed, iProviderEnv, iAdditionalRegistrationInfo = {}, iProductConfig = nil, iToolConfig = nil)
      rError = nil

      log_debug "Install Component #{iComponentName} from plugin #{iPluginCategory}/#{iPluginName} with parameters \"#{iParameters.join(' ')}\""
      log_debug "Provider environment: #{iProviderEnv.inspect}"
      log_debug "Additional installation info: #{iAdditionalRegistrationInfo.inspect}"
      log_debug "Product configuration: #{iProductConfig.inspect}"
      log_debug "Tool configuration: #{iToolConfig.inspect}"
      # Check that such a component does not exist yet
      lComponentInstallInfo = getComponentInstallInfo(iComponentName)
      if ((@ForceMode) or
          (lComponentInstallInfo == nil))
        if (lComponentInstallInfo != nil)
          log_warn "Component #{iComponentName} already exists: it has been installed on #{lComponentInstallInfo[:InstallationDate]} with the following parameters: #{lComponentInstallInfo[:InstallationParameters]}. Will force its re-installation."
        end
        @PluginsManager.access_plugin(iPluginCategory, iPluginName) do |ioPlugin|
          # Get the description to parse options
          rError, lAdditionalArgs = initPluginWithParameters(ioPlugin, iParameters, iExtraParametersAllowed)
          if (rError == nil)
            # Give some references for the plugins to use
            ioPlugin.instance_variable_set(:@PluginsManager, @PluginsManager)
            ioPlugin.instance_variable_set(:@WEACEConfigDir, @WEACEConfigDir)
            ioPlugin.instance_variable_set(:@WEACELibDir, @WEACELibDir)
            ioPlugin.instance_variable_set(:@WEACEVolatileDir, @WEACEVolatileDir)
            ioPlugin.instance_variable_set(:@WEACEEnvFile, @WEACEEnvFile)
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
                    log_warn "Configuration file #{lConfFileName} already exists. Will not overwrite it."
                  else
                    if (ioPlugin.respond_to?(:getDefaultConfig))
                      lDefaultConfig = ioPlugin.getDefaultConfig
                    end
                    generateConfigFile(iComponentName, lDefaultConfig, iParameters)
                  end
                  log_msg "Component #{iComponentName} installed successfully."
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
    # Parameters::
    # * *iType* (_String_): Type of component to check (Master|Slave)
    # * *CodeBlock*: Code called only if the component is installed
    #   * *iProviderEnv* (<em>map<Symbol,Object></em>): The corresponding Provider's environment
    #   * Return::
    #   * _Exception_: An error, or nil in case of success
    # Return::
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
      lSlaveClientInstallInfo = getComponentInstallInfo(lComponentName)
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
    # Parameters::
    # * *iType* (_String_): Type of component to check (Master|Slave)
    # * *iProductName* (_String_): Name of the Product to check
    # * *CodeBlock*: Code called only if the component is installed
    #   * *iProviderEnv* (<em>map<Symbol,Object></em>): The corresponding Provider's environment
    #   * *iProductID* (_String_): The corresponding Product ID
    #   * Return::
    #   * _Exception_: An error, or nil in case of success
    # Return::
    # * _Exception_: An error, or nil in case of success
    def checkInstalledProduct(iType, iProductName)
      return checkInstalledServerClient(iType) do |iProviderEnv|
        lError = nil

        # Then, check that the Product is installed
        lProductInstallInfo = getComponentInstallInfo(iProductName)
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
    # Parameters::
    # * *iProviderType* (_String_): The Provider Type
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # *_Exception_: An error, or nil in case of success
    def installMasterServer(iProviderType, iParameters)
      return installComponent(
        'MasterServer',
        'Master/Server',
        'WEACEMasterServer',
        iParameters,
        true,
        nil,
        {
          :ProviderID => iProviderType
        }
      )
    end

    # Install a Master Product
    #
    # Parameters::
    # * *iProductID* (_String_): The Product ID
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installMasterProduct(iProductID, iProductName, iParameters)
      return checkInstalledServerClient('Master') do |iProviderEnv|
        next installComponent(
          iProductName,
          'Master/Products',
          iProductID,
          iParameters,
          false,
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
    # Parameters::
    # * *iProcessID* (_String_): The Process to install
    # * *iProductName* (_String_): The Product on which we install the Process
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installMasterProcess(iProcessID, iProductName, iParameters)
      return checkInstalledProduct('Master', iProductName) do |iProviderEnv, iProductID|
        lProductConfig = getComponentConfigInfo(iProductName)
        next installComponent(
          "#{iProductName}.#{iProcessID}",
          "Master/Processes/#{iProductID}",
          iProcessID,
          iParameters,
          false,
          iProviderEnv,
          {},
          lProductConfig
        )
      end
    end

    # Install the SlaveClient
    #
    # Parameters::
    # * *iProviderType* (_String_): The Provider Type
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # *_Exception_: An error, or nil in case of success
    def installSlaveClient(iProviderType, iParameters)
      return installComponent(
        'SlaveClient',
        'Slave/Client',
        'WEACESlaveClient',
        iParameters,
        true,
        nil,
        {
          :ProviderID => iProviderType
        }
      )
    end

    # Install a Slave Product
    #
    # Parameters::
    # * *iProductID* (_String_): The Product ID
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installSlaveProduct(iProductID, iProductName, iParameters)
      return checkInstalledServerClient('Slave') do |iProviderEnv|
        next installComponent(
          iProductName,
          'Slave/Products',
          iProductID,
          iParameters,
          false,
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
    # Parameters::
    # * *iToolID* (_String_): Name of the Tool to install
    # * *iProductName* (_String_): Name to give this peculiar Product's installation
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installSlaveTool(iToolID, iProductName, iParameters)
      return checkInstalledProduct('Slave', iProductName) do |iProviderEnv, iProductID|
        lProductConfig = getComponentConfigInfo(iProductName)
        next installComponent(
          "#{iProductName}.#{iToolID}",
          "Slave/Tools/#{iProductID}",
          iToolID,
          iParameters,
          false,
          iProviderEnv,
          {},
          lProductConfig
        )
      end
    end

    # Install a Slave Action
    #
    # Parameters::
    # * *iToolID* (_String_): The Tool for which we install the Action
    # * *iActionID* (_String_): The Action we want to install
    # * *iProductName* (_String_): The Product on which we install the Action
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installSlaveAction(iToolID, iActionID, iProductName, iParameters)
      return checkInstalledProduct('Slave', iProductName) do |iProviderEnv, iProductID|
        lError = nil

        lProductConfig = getComponentConfigInfo(iProductName)
        lToolConfig = getComponentConfigInfo("#{iProductName}.#{iToolID}")
        # Then, check that the Tool is installed
        lComponentName = "#{iProductName}.#{iToolID}"
        lToolInstallInfo = getComponentInstallInfo(lComponentName)
        if (lToolInstallInfo != nil)
          lError = installComponent(
            "#{iProductName}.#{iToolID}.#{iActionID}",
            "Slave/Actions/#{iProductID}/#{iToolID}",
            iActionID,
            iParameters,
            false,
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
    # Parameters::
    # * *iListenerID* (_String_): The Listener ID
    # * *iParameters* (<em>list<String></em>): The additional parameters given to this component's installation
    # Return::
    # * _Exception_: An error, or nil in case of success
    def installSlaveListener(iListenerID, iParameters)
      return checkInstalledServerClient('Slave') do |iProviderEnv|
        next installComponent(
          iListenerID,
          'Slave/Listeners',
          iListenerID,
          iParameters,
          false,
          iProviderEnv
        )
      end
    end

    # Get options of this installer
    #
    # Return::
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
        if (@ComponentToInstall != nil)
          raise CommandLineError.new('Please specify only one --install option.')
        end
        @ComponentToInstall = iArg
      end
      rOptions.on('-f', '--force',
        'Force installation of components even if they were already installed.') do
        @ForceMode = true
      end
      rOptions.on('-p', '--provider <ProviderType>', String,
        '<ProviderType>: One of the possible Provider types available. Please use --detailedlist to know possible values.',
        'Specify the Provider to install the SlaveClient or MasterServer.') do |iArg|
        if (@ProviderType != nil)
          raise CommandLineError.new('Please specify only one --provider option.')
        end
        @ProviderType = iArg
      end
      rOptions.on('-r', '--product <ProductID>', String,
        '<ProductID>: One of the possible Products available. Please use --detailedlist to know possible values.',
        'Specify the Product to install.') do |iArg|
        if (@ProductID != nil)
          raise CommandLineError.new('Please specify only one --product option.')
        end
        @ProductID = iArg
      end
      rOptions.on('-s', '--as <ProductName>', String,
        '<ProductName>: Alias to give the Product\'s installation. This alias will then be used to install further Adapters on this Product.',
        'Specify the name of this Product\'s installation to be referenced later.') do |iArg|
        if (@AsProductName != nil)
          raise CommandLineError.new('Please specify only one --as option.')
        end
        @AsProductName = iArg
      end
      rOptions.on('-t', '--tool <ToolID>', String,
        '<ToolID>: One of the possible Tools available. Please use --detailedlist to know possible values.',
        'Specify the Tool on which this installation will apply.') do |iArg|
        if (@ToolID != nil)
          raise CommandLineError.new('Please specify only one --tool option.')
        end
        @ToolID = iArg
      end
      rOptions.on('-o', '--on <ProductName>', String,
        '<ProductName>: Alias given previously to a Product\'s installation.',
        'Specify on which Product the installation applies.') do |iArg|
        if (@OnProductName != nil)
          raise CommandLineError.new('Please specify only one --on option.')
        end
        @OnProductName = iArg
      end
      rOptions.on('-a', '--action <ActionID>', String,
        '<ActionID>: One of the possible Actions available. Please use --detailedlist to know possible values.',
        'Specify which Action to install on the given Product/Tool.') do |iArg|
        if (@ActionID != nil)
          raise CommandLineError.new("Please specify only one --action option.")
        end
        @ActionID = iArg
      end
      rOptions.on('-c', '--process <ProcessID>', String,
        '<ProcessID>: One of the possible Master Processes available. Please use --detailedlist to know possible values.',
        'Specify which Process to install on the given Product.') do |iArg|
        if (@ProcessID != nil)
          raise CommandLineError.new('Please specify only one --process option.')
        end
        @ProcessID = iArg
      end
      rOptions.on('-n', '--listener <ListenerID>', String,
        '<ListenerID>: One of the possible Slave Listeners available. Please use --detailedlist to know possible values.',
        'Specify which Listener to install.') do |iArg|
        if (@ListenerID != nil)
          raise CommandLineError.new('Please specify only one --listener option.')
        end
        @ListenerID = iArg
      end
      rOptions.on('--',
        'Following -- are the parameters specific to the installation of a given component (check each component\'s options with --detailedlist).')

      return rOptions
    end

  end

end

# It is possible that we are required by the test framework
if (__FILE__ == $0)
  # Initialize logging
  require 'rUtilAnts/Logging'
  RUtilAnts::Logging::install_logger_on_object(:lib_root_dir => File.expand_path("#{File.dirname(__FILE__)}/.."), :bug_tracker_url => 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
  # Create the installer, and execute it
  lError = WEACEInstall::Installer.new.execute(ARGV)
  if (lError == nil)
    exit 0
  else
    log_err "An error occurred: #{lError}."
    exit 1
  end
end
