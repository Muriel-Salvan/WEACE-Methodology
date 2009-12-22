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
  
    # Error occurring during config file parsing
    class InvalidConfigFileError < RuntimeError
    end

    class Client
      
      include WEACE::Toolbox

      # Constructor
      def initialize
        # Read the directories locations
        lWEACERepositoryDir, @WEACELibDir = getWEACERepositoryDirs
        @WEACEInstallDir = "#{lWEACERepositoryDir}/Install"
        @DefaultLogDir = "#{lWEACERepositoryDir}/Log"
        @ConfigFile = "#{lWEACERepositoryDir}/Config/SlaveClient.conf.rb"

        # Parse for plugins
        require 'rUtilAnts/Plugins'
        @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
        Dir.glob("#{@WEACELibDir}/Slave/Adapters/*").each do |iProductDir|
          if (File.directory?(iProductDir))
            lProductID = File.basename(iProductDir)
            Dir.glob("#{@WEACELibDir}/Slave/Adapters/#{lProductID}/*").each do |iToolDir|
              if (File.directory?(iToolDir))
                lToolID = File.basename(iToolDir)
                @PluginsManager.parsePluginsFromDir("Adapters/#{lProductID}/#{lToolID}", "#{@WEACELibDir}/Slave/Adapters/#{lProductID}/#{lToolID}", "WEACE::Slave::Adapters::#{lProductID}::#{lToolID}")
              end
            end
          end
        end
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

Example: -u Scripts_Validator -t TicketTracker -a Ticket_RejectDuplicate 123 456 -a Ticket_AddLinkToTask 789 234

Check http://weacemethod.sourceforge.net for details."
        lUserID = nil
        # Parse command line arguments, and check them
        # The map of actions to execute
        # map< ToolID, list< [ ActionID, Parameters ] > >
        lActions = {}
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
        lIdxCurrentAction = nil
        lBeginNewUser = false
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
              end
            else
              if (lBeginNewTool)
                # Name of the tool
                if (lActions[iArg] == nil)
                  lActions[iArg] = {}
                end
                lCurrentTool = iArg
                lBeginNewTool = false
              elsif (lBeginNewAction)
                # Name of an action
                lActions[lCurrentTool] << [ iArg, [] ]
                lIdxCurrentAction = lActions[lCurrentTool].size - 1
                lBeginNewAction = false
              elsif (lIdxCurrentAction != nil)
                # Name of a parameter
                lActions[lCurrentTool][lIdxCurrentAction][1] << iArg
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
            if (lDisplayDetails)
              # TODO
            else
              # TODO
            end
            lCancelProcess = true
          end
          if ((!lCancelProcess) and
              (lUserID != nil))
            if (lInvalid)
              # Incorrect parameters
              rError = RuntimeError.new("Incorrect parameters: \"#{iParameters.join(' ')}\"\n#{lUsage}.")
            else
              # Read the configuration file
              rError, lConfig = readConfigFile
              if (rError == nil)
                # Create log file
                require 'fileutils'
                FileUtils::mkdir_p(File.dirname(lConfig[:LogFile]))
                setLogFile(lConfig[:LogFile])
                activateLogDebug(lDebugMode)
                logInfo '== WEACE Slave Client called =='
                logDebug "* User: #{lUserID}"
                logDebug "* #{lActions.size} tools to update:"
                iActions.each do |iToolID, iActionsList|
                  logDebug "** For #{iToolID}: #{iActionsList.size} actions:"
                  iActionsList.each do |iActionInfo|
                    iActionID, iActionParameters = iActionInfo
                    logDebug "*** #{iActionID} (#{iActionParameters.inspect})"
                  end
                end
                logDebug "#{lConfig[:WEACESlaveAdapters].size} adapters configuration:"
                # map< ToolID, list< Parameters > >
                lAdapterPerTool = {}
                lIdx = 0
                lConfig[:WEACESlaveAdapters].each do |iAdapterInfo|
                  lProductID = iAdapterInfo[:Product]
                  lToolID = iAdapterInfo[:Tool]
                  # First check if this Adapter has been installed before using it
                  lInstalledDesc = getInstalledComponentDescription("Slave/Adapters/#{lProductID}/#{lToolID}")
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
                  if (lInstalledDesc == nil)
                    logDebug '** NOT installed.'
                  else
                    logDebug "** Installed on #{lInstalledDesc[:InstallationDate]} with parameters \"#{lInstalledDesc[:InstallationParameters]}\""
                    # Profit from this loop to index adapters per ToolID
                    if (lAdapterPerTool[lToolID] == nil)
                      lAdapterPerTool[lToolID] = []
                    end
                    lAdapterPerTool[lToolID] << iAdapterInfo
                  end
                  lIdx += 1
                end
                # For each tool having an action, call all the adapters for this tool
                # List of errors encountered
                lErrors = []
                lActions.each do |iToolID, iActionsList|
                  # For each adapter adapting iToolID
                  lAdapterPerTool[iToolID].each do |iAdapterInfo|
                    lProductID = iAdapterInfo[:Product]
                    lAdapterParameters = {}
                    iAdapterInfo.each do |iKey, iValue|
                      if ((iKey != :Product) and
                          (iKey != :Tool))
                        lAdapterParameters[iKey] = iValue
                      end
                    end
                    # For each action to give to this adapter
                    iActionsList.each do |iActionInfo|
                      iActionID, iActionParameters = iActionInfo
                      logDebug 'Executing action on a product using an adapter:'
                      logDebug "* Action: #{iActionID}"
                      logDebug "* Action parameters: #{iActionParameters.inspect}"
                      logDebug "* Product: #{lProductID}"
                      logDebug "* Product config: #{lAdapterParameters.inspect}"
                      logDebug "* Tool: #{iToolID}"
                      # Access the correct plugin
                      accessPlugin("Slave/Adapters/#{lProductID}/#{iToolID}", iActionID) do |ioAdapterPlugin|
                        instantiateVars(ioAdapterPlugin, lAdapterParameters)
                        begin
                          lError = ioAdapterPlugin.execute(lUserID, *iActionParameters)
                          if (lError == nil)
                            logDebug 'Adapter completed action without error.'
                          else
                            logDebug "Adapter completed with an error: #{lError}."
                            lErrors << "Adapter completed with an error: #{lError}."
                          end
                        rescue RuntimeError
                          logExc $!, "Error while executing Adapter Slave/Adapters/#{lProductID}/#{iToolID}/#{iActionID}."
                          lErrors << "Unable to execute Adapter Slave/Adapters/#{lProductID}/#{iToolID}/#{iActionID}: #{$!}"
                        end
                      end
                    end
                  end
                end
                if (!lErrors.empty?)
                  rError = RuntimeError.new("Several errors encountered:\n#{lErrors.join("\n")}")
                end
              end
            end
          end
        end

        return rError
      end
      
      private

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
            rConfig[:LogFile] = "#{@DefaultLogDir}/WEACEMasterServer.log"
          end
        end

        return rError, rConfig
      end

    end
  
  end

end

