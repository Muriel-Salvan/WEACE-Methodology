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

require 'WEACEToolkit/Common.rb'

module WEACE

  module Slave
  
    class Client
      
      include WEACE::Common

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

        # The Product that caused this error
        #   String
        attr_reader :ProductID

        # The Tool that caused this error
        #   String
        attr_reader :ToolID

        # The Action that caused this error
        #   String
        attr_reader :ActionID

        # The Adapter error
        #   String
        attr_reader :AdapterError

        # Constructor
        #
        # Parameters:
        # * *iProductID* (_String_): The Product ID
        # * *iToolID* (_String_): The Tool ID
        # * *iActionID* (_String_): The Action ID
        # * *iAdapterError* (_Exception_): The exception raised by this Adapter
        def initialize(iProductID, iToolID, iActionID, iAdapterError)
          @ProductID, @ToolID, @ActionID, @AdapterError = iProductID, iToolID, iActionID, iAdapterError
          super("Slave Adapter #{@ProductID}/#{@ToolID}/#{@ActionID} raised an error: #{@AdapterError}. Stack:\n#{@AdapterError.backtrace.join("\n")}\n")
        end

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
        # Initialize logging
        require 'rUtilAnts/Logging'
        RUtilAnts::Logging::initializeLogging(File.expand_path("#{File.dirname(__FILE__)}/.."), 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
        # Read the directories locations
        setupWEACEDirs
        # Map of Actions to be executed
        # map< String, map< String, [ list< String >, list< list< String > > ] > >
        #      ToolID       ActionID        ProductName           Parameter
        # map<
        #   ToolID,
        #   map<                              <- Set of Actions that are associated to this Tool
        #     ActionID,
        #     [
        #       list< ProductName >,          <- List of Products that are adapted to this Action
        #       list< list< Parameter > >     <- List of parameters to apply with this Action
        #     ]
        #   >
        # >
        @ActionsToExecute = {}

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
      # * _Exception_: An error, or nil in case of success
      def executeMarshalled(iUserScriptID, iSerializedActions)
        begin
          lActions = Marshal.load(iSerializedActions)
        rescue Exception
          puts "!!! Exception while unserializing data: #{$!}."
          puts $!.backtrace.join("\n")
          raise
        end

        # Convert Actions back to command line parameters
        return execute(getSlaveClientParamsFromActions(iUserScriptID, lActions))
      end
    
      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): The parameters
      # Return:
      # * _Exception_: An error, or nil in case of success
      def execute(iParameters)
        rError = nil

        # Read SlaveClient conf
        @SlaveClientConfig = getComponentConfigInfo('SlaveClient')
        if (@SlaveClientConfig == nil)
          rError = RuntimeError.new('SlaveClient has not been installed correctly. Please use WEACEInstall.rb to install it.')
        else
          # Create log file
          lLogFile = @SlaveClientConfig[:LogFile]
          if (lLogFile == nil)
            lLogFile = "#{@WEACERepositoryDir}/Log/SlaveClient.log"
          end
          require 'fileutils'
          FileUtils::mkdir_p(File.dirname(lLogFile))
          setLogFile(lLogFile)
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
          @DebugMode = false
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
                  if (@ActionsToExecute[iArg] == nil)
                    if (iArg == Tools::All)
                      # Create a new place in @ActionsToExecute for it
                      @ActionsToExecute[iArg] = {}
                      lCurrentTool = iArg
                      lCurrentAction = nil
                    else
                      logErr "Unknown Tool named #{iArg}. Please use --list to know available Tools and Actions."
                      lInvalid = true
                    end
                  else
                    lCurrentTool = iArg
                    lCurrentAction = nil
                  end
                  lBeginNewTool = false
                elsif (lBeginNewAction)
                  # Name of an action
                  if ((@ActionsToExecute[lCurrentTool] == nil) or
                      (@ActionsToExecute[lCurrentTool][iArg] == nil))
                    if (lCurrentTool == Tools::All)
                      # Add this Action
                      @ActionsToExecute[lCurrentTool][iArg] = [ [], [ [] ] ]
                      lIdxCurrentAction = 0
                      lCurrentAction = iArg
                    else
                      logErr "Action #{iArg} is not available for Tool #{lCurrentTool}. Please use --list to know available Tools and Actions."
                      lInvalid = true
                    end
                  else
                    @ActionsToExecute[lCurrentTool][iArg][1] << []
                    lIdxCurrentAction = @ActionsToExecute[lCurrentTool][iArg][1].size - 1
                    lCurrentAction = iArg
                  end
                  lBeginNewAction = false
                elsif (lIdxCurrentAction != nil)
                  # Name of a parameter
                  @ActionsToExecute[lCurrentTool][lCurrentAction][1][lIdxCurrentAction] << iArg
                else
                  # Can be other switches
                  case iArg
                  when '-h', '--help'
                    lDisplayUsage = true
                  when '-v', '--version'
                    lDisplayVersion = true
                  when '-d', '--debug'
                    @DebugMode = true
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
              outputActions(lDisplayDetails, @SlaveClientConfig[:WEACESlaveAdapters])
              lCancelProcess = true
            end
            if (!lCancelProcess)
              if (((lUserID == nil) and
                   (lIsActionPresent)) or
                  (lInvalid))
                # Incorrect parameters
                rError = CommandLineError.new("Incorrect parameters: \"#{iParameters.join(' ')}\"\n#{lUsage}.")
              else
                rError = executeActions(lUserID)
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
      # * *iProductName* (_String_): The Product name
      # * *iToolID* (_String_): The Tool ID
      # Return:
      # * _Exception_: An error, or ni in case of success
      def executeAction(iUserID, iActionID, iActionParameters, iProductName, iToolID)
        rError = nil

        # Get the ProductID
        lProductInstallInfo = getComponentInstallInfo(iProductName)
        if (lProductInstallInfo == nil)
          rError = RuntimeError.new("Product #{iProductName} is not installed but referenced among the SlaveClient's configuration.")
        elsif (lProductInstallInfo[:Product] == nil)
          rError = RuntimeError.new("Product #{iProductName}'s installation is corrupted. Installation file invalid.")
        else
          lProductID = lProductInstallInfo[:Product]
          lProductConfig = getComponentConfigInfo(iProductName)
          lToolConfig = getComponentConfigInfo("#{iProductName}.#{iToolID}")
          lActionConfig = getComponentConfigInfo("#{iProductName}.#{iToolID}.#{iActionID}")
          logDebug 'Executing action on a product using an adapter:'
          logDebug "* Product: #{iProductName} (#{lProductID})"
          logDebug "* Product config: #{lProductConfig.inspect}"
          logDebug "* Tool: #{iToolID}"
          logDebug "* Tool config: #{lToolConfig.inspect}"
          logDebug "* Action: #{iActionID}"
          logDebug "* Action config: #{lActionConfig.inspect}"
          logDebug "* Action parameters: #{iActionParameters.inspect}"
          # Access the correct plugin
          @PluginsManager.accessPlugin("Actions/#{lProductID}/#{iToolID}", iActionID) do |ioAdapterPlugin|
            ioAdapterPlugin.instance_variable_set(:@ProductConfig, lProductConfig)
            ioAdapterPlugin.instance_variable_set(:@ToolConfig, lToolConfig)
            ioAdapterPlugin.instance_variable_set(:@ActionConfig, lActionConfig)
            begin
              rError = ioAdapterPlugin.execute(iUserID, *iActionParameters)
            rescue ArgumentError
              rError = AdapterArgumentError.new("Slave Action #{lProductID}/#{iToolID}/#{iActionID} did not get valid arguments. Check parameters or the Action's signature: #{$!}.")
            rescue Exception
              rError = AdapterError.new(lProductID, iToolID, iActionID, $!)
            end
            if (rError == nil)
              logDebug 'Action completed without error.'
            else
              logDebug "Action completed with an error: #{rError}."
            end
          end
        end

        return rError
      end

      # Execute all the Actions having parameters.
      # This method uses @ActionsToExecute to get the Actions to execute.
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # Return:
      # * _ActionExecutionsError_: An error, or nil in case of success
      def executeActions(iUserID)
        rError = nil

        activateLogDebug(@DebugMode)
        logInfo '== WEACE Slave Client called =='
        dumpDebugInfo(iUserID, @SlaveClientConfig[:WEACESlaveAdapters])

        # For each tool having an action, call all the adapters for this tool.
        # List of errors that occurred on some Adapters
        # list< [ iProductID, iToolID, iActionID, iActionParameters, Exception ] >
        lErrors = []
        @ActionsToExecute.each do |iToolID, iToolInfo|
          # Don't look at Tools::All here.
          if (iToolID != Tools::All)
            # For each Action adapted in iToolID
            iToolInfo.each do |iActionID, iActionInfo|
              iProductsList, iAskedParameters = iActionInfo
              # Check out if their are additional parameters listed for All Tools
              if ((@ActionsToExecute[Tools::All] != nil) and
                  (@ActionsToExecute[Tools::All][iActionID] != nil))
                # Yes, we have extra parameters here
                lEmptyProductsList, lAllToolsAskedParameters = @ActionsToExecute[Tools::All][iActionID]
                lErrors += executeActionsForProductsList(iUserID, iProductsList, iToolID, iActionID, iAskedParameters + lAllToolsAskedParameters)
              else
                lErrors += executeActionsForProductsList(iUserID, iProductsList, iToolID, iActionID, iAskedParameters)
              end
            end
          end
        end
        # And now, if Tools::All was included, we search all Actions that were not part of @ActionsToExecute and that can also be executed
        if (@ActionsToExecute[Tools::All] != nil)
          @SlaveClientConfig[:WEACESlaveAdapters].each do |iProductName, iToolsSet|
            iToolsSet.each do |iToolID, iActionsList|
              iActionsList.each do |iActionID|
                # Check that we want to execute it and that we didn't execute this Action already
                if ((@ActionsToExecute[Tools::All][iActionID] != nil) and
                    ((@ActionsToExecute[iToolID] == nil) or
                     (@ActionsToExecute[iToolID][iActionID] == nil)))
                  lEmptyProductsList, lAskedParameters = @ActionsToExecute[iToolID][iActionID]
                  # OK, we can execute it for iProductName
                  lErrors += executeActionsForProductsList(iUserID, [iProductName], iToolID, iActionID, lAskedParameters)
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
      
      # Execute an Action given to a list of Products.
      # Check if this Product/Tool/Action is active among SlaveClient's configuration.
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iProductsList* (<em>list<String></em>): The Products list
      # * *iToolID* (_String_): The corresponding Tool ID
      # * *iActionID* (_String_): The corresponding Action ID
      # * *iAskedParameters* (<em>list<list<String>></em>): The list of parameters to apply to the Action
      # Return:
      # * <em>list<[String,String,String,list<String>,Exception]></em>: The list of errors encountered: [ ProductID, ToolID, ActionID, ActionParameters, Error ].
      def executeActionForProductsList(iUserID, iProductsList, iToolID, iActionID, iAskedParameters)
        rErrors = []

        iAskedParameters.each do |iActionParameters|
          iProductsList.each do |iProductName|
            # Check that iProductName/iToolID/iActionID is active
            if ((@SlaveClientConfig[:WEACESlaveAdapters][iProductName] != nil) and
                (@SlaveClientConfig[:WEACESlaveAdapters][iProductName][iToolID] != nil) and
                (@SlaveClientConfig[:WEACESlaveAdapters][iProductName][iToolID].include?(iActionID) != nil))
              # Check that this Action is installed
              lActionInstallInfo = getComponentInstallInfo("#{iProductName}.#{iToolID}.#{iActionID}")
              if (lActionInstallInfo == nil)
                rErrors << [ iProductName, iToolID, iActionID, iActionParameters, RuntimeError.new("Slave Action #{iProductName}/#{iToolID}/#{iActionID} is not installed.") ]
              else
                # Execute iActionID with iActionParameters for iProductID/iToolID using configuration lProductConfig
                lError = executeAction(iUserID, iActionID, iActionParameters, iProductName, iToolID)
                if (lError != nil)
                  rErrors << [ iProductName, iToolID, iActionID, iActionParameters, lError ]
                end
              end
            end
          end
        end

        return rErrors
      end

      # Display to the user the available Actions.
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
              puts "** Action: #{iActionID}, updating #{iProductsList.size} Products:"
              iProductsList.each do |iProductName|
                puts "*** #{iProductName}"
              end
            end
            puts ''
          end
        else
#          # Just display Tools/Actions that are available for installed Products
#          # map< ToolID, map< ActionID, list< ProductID > > >
#          lInstalledActions = {}
#          @Actions.each do |iToolID, iToolInfo|
#            iToolInfo.each do |iActionID, iActionInfo|
#              iProductsList, iAskedParameters = iActionInfo
#              iProductsList.each do |iProductName|
#                if (iProductInstalled)
#                  # Check config
#                  lProductConfig = getProductConfig(iSlaveAdapters, iProductID, iToolID)
#                  if (lProductConfig != nil)
#                    # Add this one
#                    if (lInstalledActions[iToolID] == nil)
#                      lInstalledActions[iToolID] = {}
#                    end
#                    if (lInstalledActions[iToolID][iActionID] == nil)
#                      lInstalledActions[iToolID][iActionID] = []
#                    end
#                    lInstalledActions[iToolID][iActionID] << iProductID
#                  end
#                end
#              end
#            end
#          end
#          # Display in a friendly way
#          puts "== #{lInstalledActions.size} available Tools:"
#          lInstalledActions.each do |iToolID, iToolInfo|
#            puts "* Tool: #{iToolID}"
#            iToolInfo.each do |iActionID, iProductsList|
#              puts "** Action: #{iActionID} (updating #{iProductsList.join(', ')})"
#            end
#          end
        end
#        puts ''
#        puts 'A given Action is available only if it meets 3 requirements:'
#        puts ' 1. It has to be present among the WEACE Toolkit distribution you are using.'
#        puts ' 2. It has to be installed (using WEACEInstall).'
#        puts " 3. It has to be registered in the configuration file (#{getConfigFileName('SlaveClient')})"
#        puts 'For more information, please visit http://weacemethod.sourceforge.net'
      end

      # Dump debugging information about WEACE Slave Client
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iSlaveAdapters* (<em>list<map<Symbol,Object>></em>): The list of WEACE Slave Adapters as stated in the configuration file
      def dumpDebugInfo(iUserID, iSlaveAdapters)
        # The User
        logDebug "* User: #{iUserID}"
        # The Actions we want to execute
        logDebug "** #{@ActionsToExecute.size} Tools have Actions to execute:"
        @ActionsToExecute.each do |iToolID, iToolInfo|
          logDebug "** Tool: #{iToolID} has #{iToolInfo.size} Actions to execute"
          iToolInfo.each do |iActionID, iActionInfo|
            iProductsList, iAskedParameters = iActionInfo
            logDebug "*** Action: #{iActionID}"
            logDebug "**** #{iProductsList.size} Products supporting this Action:"
            iProductsList.each do |iProductName|
              logDebug "***** #{iProductName}"
            end
            logDebug "**** Asked to be executed #{iAskedParameters.size} times:"
            iAskedParameters.each do |iActionParameters|
              logDebug "***** #{iActionParameters.join(' ')}"
            end
          end
        end
        # The active Products from SlaveClient configuration
        logDebug "#{iSlaveAdapters.size} active Products:"
        iSlaveAdapters.each do |iProductName, iToolsSet|
          logDebug "* Product: #{iProductName} (#{iToolsSet.size} active Tools)"
          iToolsSet.each do |iToolID, iActionsList|
            logDebug "** Tool: #{iToolID} (#{iActionsList.size} active Actions)"
            iActionsList.each do |iActionID|
              logDebug "*** Action: #{iActionID}"
            end
          end
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
                @PluginsManager.parsePluginsFromDir("Actions/#{lProductID}/#{lToolID}", "#{iDir}/#{lProductID}/#{lToolID}", "WEACE::Slave::Adapters::#{lProductID}::#{lToolID}")
              end
            end
          end
        end
      end

    end
  
  end

end

