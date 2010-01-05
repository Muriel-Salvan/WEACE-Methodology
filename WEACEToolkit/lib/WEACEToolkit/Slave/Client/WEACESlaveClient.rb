# Called using WEACEExecute.rb using the following parameters:
# <UserScriptID> [ -t <ToolID> [ -a <ActionID> <ActionParameters> ]* ]*
#
# <ActionParameters> depend on <ActionID>. Here are the possible <ActionID> values and their corresponding possible <ActionParameters>:
# * Ticket_AddLinkToTask <TicketID> <TaskID>
# * Ticket_RejectDuplicate <MasterTicketID> <SlaveTicketID>
#
# Example: ruby -w WEACEExecute.rb SlaveClient Scripts_Validator -t TicketTracker -a Ticket_RejectDuplicate 123 456 -a Ticket_AddLinkToTask 789 234
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/WEACE_Common.rb'

module WEACE

  module Slave
  
    Product_Mediawiki = 'Mediawiki'
    Product_Redmine = 'Redmine'
  
    class Client
      
      include WEACE::Toolbox

      # Error occurring during comand line parsing
      class CommandLineError < RuntimeError
      end

      # Error occurring during config file parsing
      class InvalidConfigFileError < RuntimeError
      end

      # Error occurring when arguments do not match an Adapter's signature
      class AdapterArgumentError < RuntimeError
      end

      # Error occurring when an Adapter throws an exception
      class AdapterError < RuntimeError
      end

      # Error occurring when errors were encountered during Actions executions
      class ActionExecutionsError < RuntimeError

        # The list of errors encountered
        # list< [ String,    String, String,   list< String >,   Exception ] >
        # list< [ ProductID, ToolID, ActionID, ActionParameters, Exception ] >
        attr_reader :ErrorsList

        # Constructor
        #
        # Parameters:
        # * *iErrorsList* (<em>list<[iProductID,iToolID,iActionID,iActionParameters,Exception]></em>): The list of errors
        def initialize(iErrorsList)
          lStrErrors = []
          iErrorsList.each do |iErrorInfo|
            iProductID, iToolID, iActionID, iActionParameters, iException = iErrorInfo
            lStrErrors << "Action #{iProductID}/#{iToolID}/#{iActionID} (#{iActionParameters.join(' ')}): #{iException}"
          end
          super("Several errors occurred during Actions executions: #{lStrErrors.join("\n")}")
          @ErrorsList = iErrorsList
        end

      end

      # Constructor
      def initialize
        # Read the directories locations
        lWEACERepositoryDir, @WEACELibDir = getWEACERepositoryDirs
        @WEACEInstallDir = "#{lWEACERepositoryDir}/Install"
        @DefaultLogDir = "#{lWEACERepositoryDir}/Log"
        @ConfigFile = "#{lWEACERepositoryDir}/Config/SlaveClient.conf.rb"
        # Map of Actions
        # map< String, map< String, [ list< [ String,    Boolean ] >, list< list< String > > ] > >
        #      ToolID       ActionID          ProductID, Installed?               Parameter
        # map<
        #   ToolID,
        #   map<                              <- Set of Actions that are associated to this Tool
        #     ActionID,
        #     [                               <- List of Products that are adapted to this Action
        #       list< [
        #         ProductID,
        #         Installed?                  <- Has this Adapter been installed (or is it just among plugins) ?
        #       ] >,
        #       list< list< Parameter > >     <- List of parameters to apply with this Action
        #     ]
        #   >
        # >
        @Actions = {}

        # Parse for plugins
        require 'rUtilAnts/Plugins'
        @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
        parseAdapters("#{@WEACELibDir}/Slave/Adapters")
      end
    
      # Execute the server with the configuration given serialized
      #
      # Parameters:
      # * *iUserScriptID* (_String_): The user name of the script
      # * *iSerializedActions* (_String_): The serialized actions to execute
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def executeMarshalled(iUserScriptID, iSerializedActions)
        begin
          lActions = Marshal.load(iSerializedActions)
        rescue Exception
          puts "!!! Exception while unserializing data: #{$!}."
          puts $!.backtrace.join("\n")
          raise
        end
        
        return execute(iUserScriptID, lActions)
      end
    
      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): The parameters
      # Return:
      # * _Exception_: An error, or nil in case of success
      def execute(iParameters)
        rError = nil

          lUsage = "Signature: [-h|--help] [-v|--version] [-d|--debug] [-l|--list] [-e|--detailedlist] [ -u|--user <UserID> [ -t|--tool <ToolID> [ -a|--action <ActionID> <ActionParameters> ]* ]* ]
  -h, --help:         Display help
  -v, --version:      Display version of WEACE Slave Client
  -d, --debug:        Activate debug mode (more verbose).
  -l, --list:         Display available Actions.
  -e, --detailedlist: Display available Actions in details.
  -u, --user:         Set which User executes the Actions.
    <UserID>:           User's ID used to execute Actions.
  -t, --tool:         Specify the Tool on which the Action is to be performed
    <ToolID>:           The corresponding Tool ID.
  -a, --action:       Specify an Action to execute on this given Tool.
    <ActionID>:         The ID of the Action to execute. Please use --list to know available Actions.
    <ActionParameters>: The parameters to give the Action.

Example: -u Scripts_Validator -t TicketTracker -a RejectDuplicate 123 456 -a AddLinkToTask 789 234

Check http://weacemethod.sourceforge.net for details."
        lUserID = nil
        # Parse command line arguments, and check them
        lDisplayUsage = false
        lDisplayVersion = false
        lDisplayList = false
        lDisplayDetails = false
        lDebugMode = false
        lUserID = nil
        lInvalid = false
        lBeginNewTool = false
        lCurrentTool = nil
        lBeginNewAction = false
        lCurrentAction = nil
        lIdxCurrentAction = nil
        lBeginNewUser = false
        lIsActionPresent = false
        iParameters.each do |iArg|
          if (lBeginNewUser)
            lUserID = iArg
            lBeginNewUser = false
          else
            case iArg
            when '-t', '--tool'
              if ((lBeginNewAction) or
                  ((lCurrentTool != nil) and
                   (lIdxCurrentAction == nil)))
                lInvalid = true
              else
                lBeginNewTool = true
                lIdxCurrentAction = nil
              end
            when '-a', '--action'
              if ((lBeginNewTool) or
                  (lCurrentTool == nil))
                lInvalid = true
              else
                lBeginNewAction = true
                lIdxCurrentAction = nil
                lIsActionPresent = true
              end
            else
              if (lBeginNewTool)
                # Name of the tool
                if (@Actions[iArg] == nil)
                  logErr "Unknown Tool named #{iArg}. Please use --list to know available Tools and Actions."
                  lInvalid = true
                else
                  lCurrentTool = iArg
                  lCurrentAction = nil
                end
                lBeginNewTool = false
              elsif (lBeginNewAction)
                # Name of an action
                if ((@Actions[lCurrentTool] == nil) or
                    (@Actions[lCurrentTool][iArg] == nil))
                  logErr "Action #{iArg} is not available for Tool #{lCurrentTool}. Please use --list to know available Tools and Actions."
                  lInvalid = true
                else
                  @Actions[lCurrentTool][iArg][1] << []
                  lIdxCurrentAction = @Actions[lCurrentTool][iArg][1].size - 1
                  lCurrentAction = iArg
                end
                lBeginNewAction = false
              elsif (lIdxCurrentAction != nil)
                # Name of a parameter
                @Actions[lCurrentTool][lCurrentAction][1][lIdxCurrentAction] << iArg
              else
                # Can be other switches
                case iArg
                when '-h', '--help'
                  lDisplayUsage = true
                when '-v', '--version'
                  lDisplayVersion = true
                when '-d', '--debug'
                  lDebugMode = true
                when '-l', '--list'
                  lDisplayList = true
                when '-e', '--detailedlist'
                  lDisplayList = true
                  lDisplayDetails = true
                when '-u', '--user'
                  lBeginNewUser = true
                else
                  lInvalid = true
                end
              end
            end
          end
        end
        # Execute what was asked on the command line
        if (lDisplayUsage)
          puts lUsage
        else
          lCancelProcess = false
          if (lDisplayVersion)
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
            lCancelProcess = true
          end
          if (lDisplayList)
            rError, lConfig = readConfigFile
            if (rError == nil)
              outputActions(lDisplayDetails, lConfig[:WEACESlaveAdapters])
            end
            lCancelProcess = true
          end
          if (!lCancelProcess)
            if (((lUserID == nil) and
                 (lIsActionPresent)) or
                (lInvalid))
              # Incorrect parameters
              rError = CommandLineError.new("Incorrect parameters: \"#{iParameters.join(' ')}\"\n#{lUsage}.")
            else
              # Read the configuration file
              rError, lConfig = readConfigFile
              if (rError == nil)
                # Here we can execute Actions correctly
                # Create log file
                require 'fileutils'
                FileUtils::mkdir_p(File.dirname(lConfig[:LogFile]))
                setLogFile(lConfig[:LogFile])
                activateLogDebug(lDebugMode)
                logInfo '== WEACE Slave Client called =='
                dumpDebugInfo(lUserID, lConfig[:WEACESlaveAdapters])
                rError = executeActions(lUserID, lConfig[:WEACESlaveAdapters])
              end
            end
          end
        end

        return rError
      end
      
      private

      # Get the configuration of the given Product/Tool
      #
      # Parameters:
      # * *iSlaveAdapters* (<em>list<map<Symbol,Object>></em>): The list of WEACE Slave Adapters as stated in the configuration file
      # * *iProductID* (_String_): The Product ID
      # * *iToolID* (_String_): The Tool ID
      # Return:
      # * <em>map<Symbol,Object></em>: The corresponding configuration, or nil if not found
      def getProductConfig(iSlaveAdapters, iProductID, iToolID)
        rConfig = nil

        iSlaveAdapters.each do |iSlaveAdapterInfo|
          if ((iSlaveAdapterInfo[:Product] == iProductID) and
              (iSlaveAdapterInfo[:Tool] == iToolID))
            rConfig = iSlaveAdapterInfo
            break
          end
        end

        return rConfig
      end

      # Execute an Action for a given Product/Tool given its configuration
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iActionID* (_String_): The Action ID
      # * *iActionParameters* (<em>list<String></em>): The parameters to give to the Action
      # * *iProductID* (_String_): The Product ID
      # * *iToolID* (_String_): The Tool ID
      # * *iProductConfig* (<em>map<Symbol,Object></em>): The Product configuration
      # Return:
      # * _Exception_: An error, or ni in case of success
      def executeAction(iUserID, iActionID, iActionParameters, iProductID, iToolID, iProductConfig)
        rError = nil

        logDebug 'Executing action on a product using an adapter:'
        logDebug "* Action: #{iActionID}"
        logDebug "* Action parameters: #{iActionParameters.inspect}"
        logDebug "* Product: #{iProductID}"
        logDebug "* Product config: #{iProductConfig.inspect}"
        logDebug "* Tool: #{iToolID}"
        # Access the correct plugin
        @PluginsManager.accessPlugin("Adapters/#{iProductID}/#{iToolID}", iActionID) do |ioAdapterPlugin|
          instantiateVars(ioAdapterPlugin, iProductConfig)
          begin
            rError = ioAdapterPlugin.execute(iUserID, *iActionParameters)
          rescue ArgumentError
            rError = AdapterArgumentError.new("Adapter #{iProductID}/#{iToolID}/#{iActionID} did not get valid arguments. Check parameters or the Adapter's signature: #{$!}.")
          rescue Exception
            rError = AdapterError.new("Adapter #{iProductID}/#{iToolID}/#{iActionID} failed with error: #{$!}.")
          end
          if (rError == nil)
            logDebug 'Adapter completed action without error.'
          else
            logDebug "Adapter completed with an error: #{rError}."
          end
        end

        return rError
      end

      # Execute all the Actions having parameters.
      # This method uses @Actions to get the possible Actions.
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iSlaveAdapters* (<em>list<map<Symbol,Object>></em>): The list of WEACE Slave Adapters as stated in the configuration file
      # Return:
      # * _ActionExecutionsError_: An error, or nil in case of success
      def executeActions(iUserID, iSlaveAdapters)
        rError = nil

        # For each tool having an action, call all the adapters for this tool.
        # List of errors that occurred on some Adapters
        # list< [ iProductID, iToolID, iActionID, iActionParameters, Exception ] >
        lErrors = []
        @Actions.each do |iToolID, iToolInfo|
          # For each adapter adapting iToolID
          iToolInfo.each do |iActionID, iActionInfo|
            iProductsList, iAskedParameters = iActionInfo
            iAskedParameters.each do |iActionParameters|
              iProductsList.each do |iProductInfo|
                iProductID, iProductInstalled = iProductInfo
                if (iProductInstalled)
                  # Check configuration for this Product
                  lProductConfig = getProductConfig(iSlaveAdapters, iProductID, iToolID)
                  if (lProductConfig != nil)
                    # Execute iActionID with iActionParameters for iProductID/iToolID using configuration lProductConfig
                    lError = executeAction(iUserID, iActionID, iActionParameters, iProductID, iToolID, lProductConfig)
                    if (lError != nil)
                      lErrors << [ iProductID, iToolID, iActionID, iActionParameters, lError ]
                    end
                  end
                end
              end
            end
          end
        end
        if (!lErrors.empty?)
          rError = ActionExecutionsError.new(lErrors)
        end

        return rError
      end
      
      # Display to the user the available Actions.
      # Uses @Actions.
      #
      # Parameters:
      # * *iDisplayDetails* (_Boolean_): Do we display detailed report ?
      # * *iSlaveAdapters* (<em>list<map<Symbol,Object>></em>): The list of WEACE Slave Adapters as stated in the configuration file
      def outputActions(iDisplayDetails, iSlaveAdapters)
        if (iDisplayDetails)
          puts "== #{@Actions.size} available Tools (please note you can only use those that are Installed AND Configured):"
          puts ''
          @Actions.each do |iToolID, iToolInfo|
            puts "* Tool: #{iToolID} (#{iToolInfo.size} available Actions for this Tool):"
            iToolInfo.each do |iActionID, iActionInfo|
              iProductsList, iAskedParameters = iActionInfo
              logDebug "** Action: #{iActionID}, updating #{iProductsList.size} Products:"
              iProductsList.each do |iProductInfo|
                iProductID, iProductInstalled = iProductInfo
                lStrInstalled = nil
                if (iProductInstalled)
                  lStrInstalled = 'Installed'
                else
                  lStrInstalled = 'NOT Installed'
                end
                # Check if it is among the configured Slave Adapters.
                lProductConfig = getProductConfig(iSlaveAdapters, iProductID, iToolID)
                lStrConfig = nil
                if (lProductConfig == nil)
                  lStrConfig = 'NOT Configured'
                else
                  lStrConfig = 'Configured'
                end
                logDebug "*** #{iProductID} (#{lStrInstalled}) (#{lStrConfig})"
              end
            end
          end
        else
          # Just display Tools/Actions that are available for installed Products
          # map< ToolID, map< ActionID, list< ProductID > > >
          lInstalledActions = {}
          @Actions.each do |iToolID, iToolInfo|
            iToolInfo.each do |iActionID, iActionInfo|
              iProductsList, iAskedParameters = iActionInfo
              iProductsList.each do |iProductInfo|
                iProductID, iProductInstalled = iProductInfo
                if (iProductInstalled)
                  # Check config
                  lProductConfig = getProductConfig(iSlaveAdapters, iProductID, iToolID)
                  if (lProductConfig != nil)
                    # Add this one
                    if (lInstalledActions[iToolID] == nil)
                      lInstalledActions[iToolID] = {}
                    end
                    if (lInstalledActions[iToolID][iActionID] == nil)
                      lInstalledActions[iToolID][iActionID] = []
                    end
                    lInstalledActions[iToolID][iActionID] << iProductID
                  end
                end
              end
            end
          end
          # Display in a friendly way
          puts "== #{lInstalledActions.size} available Tools:"
          lInstalledActions.each do |iToolID, iToolInfo|
            puts "* Tool: #{iToolID}"
            iToolInfo.each do |iActionID, iProductsList|
              puts "** Action: #{iActionID} (updating #{iProductsList.join(', ')})"
            end
          end
        end
        puts ''
        puts 'A given Action is available only if it meets 3 requirements:'
        puts ' 1. It has to be present among the WEACE Toolkit distribution you are using.'
        puts ' 2. It has to be installed (using WEACEInstall).'
        puts " 3. It has to be registered in the configuration file (#{@ConfigFile})"
        puts 'For more information, please visit http://weacemethod.sourceforge.net'
      end

      # Dump debugging information about WEACE Slave Client
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iSlaveAdapters* (<em>list<map<Symbol,Object>></em>): The list of WEACE Slave Adapters as stated in the configuration file
      def dumpDebugInfo(iUserID, iSlaveAdapters)
        logDebug "* User: #{iUserID}"
        logDebug "** #{@Actions.size} Tools have Actions:"
        @Actions.each do |iToolID, iToolInfo|
          logDebug "** Tool: #{iToolID} has #{iToolInfo.size} Actions"
          iToolInfo.each do |iActionID, iActionInfo|
            iProductsList, iAskedParameters = iActionInfo
            logDebug "*** Action: #{iActionID}"
            logDebug "**** #{iProductsList.size} Products:"
            iProductsList.each do |iProductInfo|
              iProductID, iProductInstalled = iProductInfo
              if (iProductInstalled)
                logDebug "***** #{iProductID} (Installed)"
              else
                logDebug "***** #{iProductID} (NOT Installed)"
              end
            end
            logDebug "**** Asked to be executed #{iAskedParameters.size} times:"
            iAskedParameters.each do |iActionParameters|
              logDebug "***** #{iActionParameters.join(' ')}"
            end
          end
        end
        logDebug "#{iSlaveAdapters.size} Adapters configuration:"
        lIdx = 0
        iSlaveAdapters.each do |iAdapterInfo|
          lProductID = iAdapterInfo[:Product]
          lToolID = iAdapterInfo[:Tool]
          # First check if this Adapter has been installed before using it
          logDebug "* Adapter n.#{lIdx}:"
          logDebug "** Product: #{lProductID}"
          logDebug "** Tool: #{lToolID}"
          logDebug '** Parameters:'
          iAdapterInfo.each do |iKey, iValue|
            if ((iKey != :Product) and
                (iKey != :Tool))
              logDebug "** #{iKey}: #{iValue.inspect}"
            end
          end
          lIdx += 1
        end
      end
      
      # Parse WEACE Slave Adapters from a given Adapters directory
      #
      # Parameters:
      # * *iDir* (_String_): The directory in which Adapters are to be parsed
      def parseAdapters(iDir)
        Dir.glob("#{iDir}/*").each do |iProductDir|
          if (File.directory?(iProductDir))
            lProductID = File.basename(iProductDir)
            Dir.glob("#{iDir}/#{lProductID}/*").each do |iToolDir|
              if (File.directory?(iToolDir))
                lToolID = File.basename(iToolDir)
                @PluginsManager.parsePluginsFromDir("Adapters/#{lProductID}/#{lToolID}", "#{iDir}/#{lProductID}/#{lToolID}", "WEACE::Slave::Adapters::#{lProductID}::#{lToolID}")
                # Register those Actions
                lNames = @PluginsManager.getPluginNames("Adapters/#{lProductID}/#{lToolID}")
                if (!lNames.empty?)
                  lNames.each do |iActionID|
                    # Check if this Adapter has been installed
                    lInstalledDesc = getInstalledComponentDescription("Slave/Adapters/#{lProductID}/#{lToolID}/#{iActionID}")
                    registerAction(lToolID, iActionID, lProductID, (lInstalledDesc != nil))
                  end
                end
              end
            end
          end
        end
      end

      # Register a new Action
      #
      # Parameters:
      # * *iToolID* (_String_): The Tool ID
      # * *iActionID* (_String_): The Action ID
      # * *iProductID* (_String_): The Product ID
      # * *iIsInstalled* (_Boolean_): Is the Action installed ?
      def registerAction(iToolID, iActionID, iProductID, iIsInstalled)
        if (@Actions[iToolID] == nil)
          @Actions[iToolID] = {}
        end
        if (@Actions[iToolID][iActionID] == nil)
          @Actions[iToolID][iActionID] = [ [], [] ]
        end
        @Actions[iToolID][iActionID][0] << [ iProductID, iIsInstalled ]
      end

      # Read the configuration file
      #
      # Return:
      # * _Exception_: An error, or nil in case of success
      # * <em>map<Symbol,Object></em>: The configuration
      def readConfigFile
        rError = nil
        rConfig = nil

        if (!File.exists?(@ConfigFile))
          # Create a default config file
          require 'fileutils'
          FileUtils::mkdir_p(File.dirname(@ConfigFile))
          File.open(@ConfigFile, 'w') do |oFile|
            oFile << "
# This configuration file has been generated by WEACESlaveClient on #{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}.
# You can edit it to reflect your configuration.
# Please check http://weacemethod.sourceforge.net for details about the contents of this file.

{
  # Log file used
  # Optional, Defaults to WEACE repository log file, String
  # :LogFile => '/var/log/WEACESlaveClient.log',

  # Registered WEACE Slave Adapters that are reachable from this WEACE Slave Client
  # Mandatory, list< map< Symbol, Object > >
  :WEACESlaveAdapters => [
  #   {
  #     :Product => 'Redmine',
  #     :Tool => Tools::TicketTracker,
  #     :RedmineDir => '/home/groups/m/my/myproject/redmine',
  #     :DBHost => 'mysql-r',
  #     :DBName => 'redminedb',
  #     :DBUser => 'dbuser',
  #     :DBPassword => 'dbpassword'
  #   },
  #   {
  #     :Product => 'MediaWiki',
  #     :Tool => Tools::Wiki,
  #     :MediaWikiDir => '/home/groups/m/my/myproject/htdocs/wiki'
  #   }
  ]
}
"
          end
        end
        # Read the file
        begin
          File.open(@ConfigFile, 'r') do |iFile|
            rConfig = eval(iFile.read)
            # Check mandatory parameters
            if (rConfig[:WEACESlaveAdapters] == nil)
              rError = InvalidConfigFileError.new("Configuration file #{@ConfigFile} does not declare :WEACESlaveAdapters attribute. You can either edit it or delete it to create a new one.")
            end
          end
        rescue Exception
          rError = InvalidConfigFileError.new("Configuration file #{@ConfigFile} seems to be corrupted: #{$!}. You can either edit it or delete it to create a new one.")
        end
        if (rError == nil)
          # Complete the configuration if needed
          if (rConfig[:LogFile] == nil)
            rConfig[:LogFile] = "#{@DefaultLogDir}/WEACESlaveClient.log"
          end
        end

        return rError, rConfig
      end

    end
  
  end

end

