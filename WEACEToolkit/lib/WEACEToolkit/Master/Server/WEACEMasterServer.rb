# Called using WEACEExecute.rb
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Common'

module WEACE

  module Master

    # This class is used by the processing scripts to give actions to Slave Clients
    class SlaveActions

      # The Slave Actions
      #   map< String, map< String,   list< list< String > > > >
      #   map< ToolID, map< ActionID, list< Parameters     > > >
      attr_reader :SlaveActions
    
      # Constructor
      def initialize
        # map< String, map< String,   list< list< String > > > >
        # map< ToolID, map< ActionID, list< Parameters     > > >
        @SlaveActions = {}
      end
    
      # Constructor
      #
      # Parameters:
      # * *iToolID* (_String_): The tool ID
      # * *iActionID* (_String_): The action ID
      # * *iParameters* (<em>list<String></em>): Additional parameters to give the Slave Client
      def addSlaveAction(iToolID, iActionID, *iParameters)
        if (@SlaveActions[iToolID] == nil)
          @SlaveActions[iToolID] = {}
        end
        if (@SlaveActions[iToolID][iActionID] == nil)
          @SlaveActions[iToolID][iActionID] = []
        end
        @SlaveActions[iToolID][iActionID] << iParameters
      end
      
    end

    # This file is used to encapsulate files to be transfered.
    # This way, Senders are free to use any method they want to transfer files.
    class TransferFile

      # The local file name
      #   String
      attr_reader :LocalFileName

      # Constructor
      #
      # Parameters:
      # * *iLocalFileName* (_String_): The encapsulated file name to transfer
      def initialize(iLocalFileName)
        @LocalFileName = iLocalFileName
      end
      
    end

    class Server

      # Error occurring during comand line parsing
      class CommandLineError < RuntimeError
      end

      # Error occurring during config file parsing
      class InvalidConfigFileError < RuntimeError
      end

      include WEACE::Common

      # Constructor
      def initialize
        # Initialize logging if needed
        if (!defined?(RUtilAnts::Logging))
          require 'rUtilAnts/Logging'
          RUtilAnts::Logging::initializeLogging(File.expand_path("#{File.dirname(__FILE__)}/.."), 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
        end
        # Read the directories locations
        setupWEACEDirs
        @SlaveClientQueuesDir = "#{@WEACEVolatileDir}/MasterServer/SlaveClientQueues"

        # Parse for plugins
        require 'rUtilAnts/Plugins'
        @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
        @PluginsManager.parsePluginsFromDir('Processes', "#{@WEACELibDir}/Master/Server/Processes", 'WEACE::Master::Server::Processes')
        @PluginsManager.parsePluginsFromDir('Senders', "#{@WEACELibDir}/Master/Server/Senders", 'WEACE::Master::Server::Senders')
      end

      # Get options of the WEACE Master Server
      #
      # Return:
      # * _OptionParser_: The options parser
      def getOptions
        rOptions = OptionParser.new

        rOptions.banner = '[-h|--help] [-v|--version] [-d|--debug] [-l|--list] [-e|--detailedlist] [-s|--send] [-p|--process <ProcessID> -u|--user <UserID> -- <ProcessParameters>]'
        # Options are defined here
        rOptions.on('-h', '--help',
          'Display help on this script.') do
          puts rOptions
        end
        rOptions.on('-p', '--process <ProcessID>', String,
          '<ProcessID>: ID of a Process to perform.',
          'Please use --list to know available processes.') do |iArg|
          @ProcessID = iArg
        end
        rOptions.on('-u', '--user <UserID>', String,
          '<UserID>: User ID that performs the process.') do |iArg|
          @UserID = iArg
        end
        rOptions.on('-d', '--debug',
          'Execute in debug mode (more verbose).') do
          @DebugMode = true
        end
        rOptions.on('-l', '--list',
          'Give a list of all Processes available.') do
          @OutputComponents = true
        end
        rOptions.on('-e', '--detailedlist',
          'Give a list with details of all Processes available.') do
          @OutputComponents = true
          @OutputDetails = true
        end
        rOptions.on('-v', '--version',
          'Get version of this WEACE Toolkit release.') do
          @OutputVersion = true
        end
        rOptions.on('-s', '--send',
          'Send remaining SlaveActions to the SlaveClients.') do
          @Send = true
        end
        rOptions.on('--',
          'Following -- are the parameters specific to the execution of the given Process (check each Process\'s options with --detailedlist).')

        return rOptions
      end

      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): The list of parameters
      # Return:
      # * _Exception_: An error, or nil in case of success
      def execute(iParameters)
        rError = nil

        # Read SlaveClient conf
        @MasterServerConfig = getComponentConfigInfo('MasterServer')
        if (@MasterServerConfig == nil)
          rError = RuntimeError.new('MasterServer has not been installed correctly. Please use WEACEInstall.rb to install it.')
        else
          # Create log file
          lLogFile = @MasterServerConfig[:LogFile]
          if (lLogFile == nil)
            lLogFile = "#{@WEACERepositoryDir}/Log/MasterServer.log"
          end
          require 'fileutils'
          FileUtils::mkdir_p(File.dirname(lLogFile))
          setLogFile(lLogFile)
          @DebugMode = false
          @ForceMode = false
          @ProcessID = nil
          @UserID = nil
          @OutputComponents = false
          @OutputDetails = false
          @OutputVersion = false
          @Send = false
          lOptions = getOptions
          if (iParameters.size == 0)
            puts lOptions
            rError = CommandLineError.new('No parameter specified.')
          else
            # Parse options
            lMasterArgs, lProcessArgs = splitParameters(iParameters)
            begin
              lOptions.parse(lMasterArgs)
            rescue Exception
              puts lOptions
              rError = $!
            end
            if (rError == nil)
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
                if (@OutputDetails)
                  # TODO
                else
                  # Display what is accessible
                  lProcesses = @PluginsManager.getPluginNames('Processes')
                  puts "== #{lProcesses.size} available Processes: #{lProcesses.join(', ')}"
                end
              end
              if (@ProcessID == nil)
                # If we send SlaveActions, do it here
                if (@Send)
                  rError = performRemainingSlaveActions
                end
              else
                if (@UserID == nil)
                  rError = CommandLineError.new('You must specify the UserID initiating this Process with --user option.')
                else
                  activateLogDebug(@DebugMode)
                  # Log startup
                  logInfo '== WEACE Master Server called =='
                  logDebug "* User: #{@UserID}"
                  logDebug "* Process: #{@ProcessID}"
                  logDebug "* Parameters: #{lProcessArgs.join(' ')}"
                  logDebug "#{@MasterServerConfig[:WEACESlaveClients].size} clients configuration:"
                  lIdx = 0
                  @MasterServerConfig[:WEACESlaveClients].each do |iSlaveClientInfo|
                    logDebug "* Client n.#{lIdx}:"
                    logDebug "** Type: #{iSlaveClientInfo[:Type]}"
                    logDebug "** #{iSlaveClientInfo[:Tools].size} tools are installed on this client:"
                    iSlaveClientInfo[:Tools].each do |iToolID|
                      logDebug "*** #{iToolID}"
                    end
                    logDebug '** Parameters:'
                    iSlaveClientInfo.each do |iKey, iValue|
                      if ((iKey != :Type) and
                          (iKey != :Tools))
                        logDebug "** #{iKey}: #{iValue.inspect}"
                      end
                    end
                    lIdx += 1
                  end
                  # Check that ProcessID exists
                  @PluginsManager.accessPlugin('Processes', @ProcessID) do |iProcessPlugin|
                    # Get options from the plugin and parse them
                    lProcessOptions = iProcessPlugin.getOptions
                    # Parse options
                    begin
                      lRemainingArgs = lProcessOptions.parse(lProcessArgs)
                    rescue Exception
                      puts lProcessOptions
                      rError = $!
                    end
                    if (rError == nil)
                      # Call the corresponding script, and get its summary of actions to propagate to the Slave Clients.
                      lSlaveActions = SlaveActions.new
                      begin
                        rError = iProcessPlugin.processScript(lSlaveActions, lRemainingArgs)
                      rescue Exception
                        rError = $!
                      end
                      if (rError == nil)
                        # Gather a list of errors
                        # list< String >
                        lErrors = []
                        # And now call concerned Slave Clients with the returned Slave Actions to perform
                        @MasterServerConfig[:WEACESlaveClients].each do |iSlaveClientInfo|
                          # Filter out SlaveActions that have nothing to do with this SlaveClient
                          # map< ToolID, map< ActionID, list< Parameters > > >
                          lSlaveActionsForClient = {}
                          lSlaveActions.SlaveActions.each do |iToolID, iSlaveActionsList|
                            if ((iSlaveClientInfo[:Tools].include?(iToolID)) or
                                (iSlaveClientInfo[:Tools].include?(Tools::All)) or
                                (iToolID == Tools::All))
                              # These Actions apply to this client.
                              lSlaveActionsForClient[iToolID] = iSlaveActionsList
                            end
                          end
                          # Add this information to the queue of SlaveActions to send to this client
                          lError = pushSlaveActions(@UserID, iSlaveClientInfo, lSlaveActionsForClient)
                          if (lError != nil)
                            lErrors << "An error occurred while pushing Slave Actions to the processing queue: #{lError}"
                          end
                        end
                        # Ask the processing queues to perform
                        lError = performRemainingSlaveActions
                        if (lError != nil)
                          lErrors << "An error occurred while performing remaining Actions: #{lError}"
                        end
                        if (!lErrors.empty?)
                          rError = RuntimeError.new("Several errors encountered:\n#{lErrors.join("\n")}")
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        
        return rError
      end

      private

      # Add a set of Slave Actions to be performed
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID initiating those SlaveActions
      # * *iSlaveClientInfo* (<em>map<Symbol,Object></em>): The SlaveClient's information
      # * *iSlaveActions* (<em>map<ToolID,map<ActionID,list<Parameters>>></em>): The SlaveActions to perform on this client
      # Return:
      # * _Exception_: An error, or nil in case of success
      def pushSlaveActions(iUserID, iSlaveClientInfo, iSlaveActions)
        rError = nil

        # Get errors
        # list< String >
        lErrors = []
        # 1- Add the files to be transferred to the remanent files
        iSlaveActions.each do |iToolID, iSlaveActionsList|
          # Gather the list of files that are among those SlaveActions
          iSlaveActionsList.each do |iActionID, iParametersLists|
            iParametersLists.each do |iParametersList|
              iParametersList.each do |iParameter|
                if (iParameter.is_a?(TransferFile))
                  lError = addLocalFileToBeTransfered(iParameter.LocalFileName)
                  if (lError != nil)
                    lErrors << "Error while adding local file #{iParameter.LocalFileName} to the list of transfer files: #{lError}"
                  end
                end
              end
            end
          end
        end
        # 2- Get the queue associated to this SlaveClientInfo
        lError, lSlaveClientQueue = getSlaveClientQueue(iSlaveClientInfo)
        if (lError == nil)
          # 3- Push the new SlaveActions
          lSlaveClientQueue << [ iUserID, iSlaveActions ]
          # 4- Save the SlaveClient queue
          lError = putSlaveClientQueue(iSlaveClientInfo, lSlaveClientQueue)
          if (lError != nil)
            lErrors << "Error while saving SlaveClient's processing queue for #{iSlaveClientInfo.inspect}: #{lError}"
          end
        else
          lErrors << "Error while retrieving SlaveClient's processing queue for #{iSlaveClientInfo.inspect}: #{lError}"
        end
        # Gather errors
        if (!lErrors.empty?)
          rError = RuntimeError.new("Several errors have been encountered: #{lErrors.join(', ')}")
        end

        return rError
      end

      # Mark a file to be transfered.
      #
      # Parameters:
      # * *iLocalFileName* (_String_): The local file name
      # Return:
      # * _Exception_: An error, or nil in case of success
      def addLocalFileToBeTransfered(iLocalFileName)
        rError = nil

        # Get the set of files to be transfered
        rError, lTransferFiles = getFilesToBeTransfered
        if (rError == nil)
          # Increment its usage counter
          if (lTransferFiles[iLocalFileName] == nil)
            lTransferFiles[iLocalFileName] = 1
          else
            lTransferFiles[iLocalFileName] += 1
          end
          # Write the files to be transfered
          rError = putFilesToBeTransfered(lTransferFiles)
        end

        return rError
      end

      # Perform the remaining Slave Actions to be sent to Slave Clients
      #
      # Return:
      # * _Exception_: An error, or nil in case of success
      def performRemainingSlaveActions
        rError = nil

        # Gather errors
        # list< String >
        lErrors = []
        # Loop on every SlaveClient queue we have
        lForEachError = foreachSlaveClientQueue do |iSlaveClientInfo, iSlaveClientQueue|
          # Loop on every SlaveActions to send, unless there is an error.
          # Clone it as we will modify it
          lSlaveClientQueue = iSlaveClientQueue.dup
          while (!lSlaveClientQueue.empty?)
            # Get the first item
            lUserID, lSlaveActions = lSlaveClientQueue[0]
            # Process it
            lError = sendSlaveActions(lUserID, iSlaveClientInfo, lSlaveActions)
            if (lError == nil)
              # OK, remove it from the queue
              lSlaveClientQueue.delete_at(0)
              # Remove usage counters from files we have just transferred
              lError = markFilesTransfered(lSlaveActions)
              if (lError != nil)
                lErrors << "Error while marking files as transfered for client #{iSlaveClientInfo.inspect}: #{lError}"
              end
            else
              lErrors << "Error while processing queue for client #{iSlaveClientInfo.inspect}: #{lError}"
              # Keep it, and stop processing this queue
              break
            end
          end
          # Update the queue by returning it to the loop
          next lSlaveClientQueue
        end
        if (lForEachError != nil)
          lErrors << "Error while looping among SlaveClient queues: #{lForEachError}"
        end
        if (!lErrors.empty?)
          rError = RuntimeError.new("Several errors encountered:\n#{lErrors.join("\n")}")
        end

        return rError
      end

      # Mark files present in those SlaveActions as transfered.
      # Effectively remove files that are not meant to be transfered anymore.
      #
      # Parameters:
      # * *iSlaveActions* (<em>map<ToolID,map<ActionID,list<Parameters>>></em>): The SlaveActions containing references to files to delete.
      def markFilesTransfered(iSlaveActions)
        rError = nil

        # Get the set of files to be transfered
        rError, lTransferFiles = getFilesToBeTransfered
        if (rError == nil)
          # Decrement usage counters for every file having been transfered
          # Keep trace of errors
          # list< String >
          lErrors = []
          iSlaveActions.each do |iToolID, iActionsInfo|
            iActionsInfo.each do |iActionID, iParametersLists|
              iParametersLists.each do |iParameters|
                iParameters.each do |iParameter|
                  if (iParameter.is_a?(TransferFile))
                    if (lTransferFiles[iParameter.LocalFileName] == nil)
                      logErr "File #{iParameter.LocalFileName} should have been marked for transfer, but no trace of it was found. It appears the transfer files database might be corrupted."
                    else
                      lTransferFiles[iParameter.LocalFileName] -= 1
                      if (lTransferFiles[iParameter.LocalFileName] == 0)
                        lTransferFiles.delete(iParameter.LocalFileName)
                      end
                    end
                    if (lTransferFiles[iParameter.LocalFileName] == nil)
                      begin
                        # Remove the file for real
                        File.unlink(iParameter.LocalFileName)
                      rescue Exception
                        lErrors << "Error while deleting file #{iParameter.LocalFileName}: #{$!}"
                      end
                    end
                  end
                end
              end
            end
          end
          # Write the files to be transfered
          lError = putFilesToBeTransfered(lTransferFiles)
          if (lError != nil)
            lErrors << "Error while writing files to be transfered: #{lError}"
          end
          if (!lErrors.empty?)
            rError = RuntimeError.new("Several errors were encountered: #{lErrors.join(', ')}")
          end
        end

        return rError
      end

      # Get the set of files to be transfered, with their counters
      #
      # Return:
      # * _Exception_: An error, or nil if success
      # * <em>map<String,Integer></em>: The set of files to transfer, along with their counters.
      def getFilesToBeTransfered
        rError = nil
        rTransferFiles = {}

        lTransfersFile = "#{@SlaveClientQueuesDir}/TransferFiles"
        if (File.exists?(lTransfersFile))
          begin
            File.open(lTransfersFile, 'rb') do |iFile|
              rTransferFiles = Marshal.load(iFile.read)
            end
          rescue Exception
            rError = $!
          end
        end

        return rError, rTransferFiles
      end

      # Save files to be transferred
      #
      # Parameters:
      # * <em>map<String,Integer></em>: The set of files to transfer, along with their counters.
      # Return:
      # * _Exception_: An error, or nil if success
      def putFilesToBeTransfered(iTransferFiles)
        rError = nil

        lTransfersFile = "#{@SlaveClientQueuesDir}/TransferFiles"
        begin
          File.open(lTransfersFile, 'wb') do |iFile|
            iFile.write(Marshal.dump(iTransferFiles))
          end
        rescue Exception
          rError = $!
        end

        return rError
      end

      # Loop among every SlaveClient's non-empty queues
      #
      # Parameters:
      # * *CodeBlock*: Code called for each SlaveClient's queue found non-empty:
      # ** *iSlaveClientInfo* (<em>map<Symbol,Object></em>): The SlaveClient's information
      # ** *iSlaveClientQueue* (<em>list<[String,map<ToolID,map<ActionID,list<Parameters>>>]></em>): The SlaveClient's queue
      # ** Return:
      # ** <em>list<[String,map<ToolID,map<ActionID,list<Parameters>>>]></em>: The new SlaveClient's queue to store, replacing the one given
      # Return:
      # * _Exception_: An error, or nil in case of success
      def foreachSlaveClientQueue
        rError = nil

        # Get the list of SlaveClientInfo having a non-empty SlaveClient queue
        rError, lLstSlaveClients = getRemainingSlaveClientInfos
        if (rError == nil)
          # Keep trace of errors
          # list< String >
          lErrors = []
          lLstSlaveClients.each do |iSlaveClientInfo|
            # Get the queue
            lError, lSlaveClientQueue = getSlaveClientQueue(iSlaveClientInfo)
            if (lError == nil)
              # Call client's code
              lNewSlaveClientQueue = yield(iSlaveClientInfo, lSlaveClientQueue)
              # Save the queue
              lError = putSlaveClientQueue(iSlaveClientInfo, lNewSlaveClientQueue)
              if (lError != nil)
                lErrors << "Error while saving SlaveClient's queue for #{iSlaveClientInfo.inspect}: #{lError}"
              end
            else
              lErrors << "Error while getting SlaveClient's queue for #{iSlaveClientInfo.inspect}: #{lError}"
            end
          end
          if (!lErrors.empty?)
            rError = RuntimeError.new("Several errors encountered: #{lErrors.join(', ')}")
          end
        end

        return rError
      end

      # Get the list of SlaveClients' info that have a non-empty processing queue
      #
      # Return:
      # * _Exception_: An error, or nil in case of success.
      # * <em>list<map<Symbol,Object>></em>): The list of SlaveClients' info.
      def getRemainingSlaveClientInfos
        rError = nil
        rLstSlaveClients = []

        # Read the files giving each SlaveClients' info.
        begin
          Dir.glob("#{@SlaveClientQueuesDir}/*.Info").each do |iFileName|
            File.open(iFileName, 'rb') do |iFile|
              rLstSlaveClients << Marshal.load(iFile.read)
            end
          end
        rescue Exception
          rError = $!
        end

        return rError, rLstSlaveClients
      end

      # Get the SlaveClient processing queue corresponding to a given SlaveClient info.
      # Initialize an empty queue if none was set.
      #
      # Parameters:
      # * *iSlaveClientInfo* (<em>map<Symbol,Object></em>): The SlaveClient info
      # Return:
      # * _Exception_: An error, or nil if success
      # * <em>list<[String,map<ToolID,map<ActionID,list<Parameters>>>]></em>: The SlaveClient queue
      def getSlaveClientQueue(iSlaveClientInfo)
        rError = nil
        rSlaveClientQueue = []

        # Get the hash of this SlaveClient info
        lHash = sprintf('%X', iSlaveClientInfo.hash.abs)
        lQueueFile = "#{@SlaveClientQueuesDir}/#{lHash}.Queue"
        if (File.exists?(lQueueFile))
          begin
            File.open(lQueueFile, 'rb') do |iFile|
              rSlaveClientQueue = Marshal.load(iFile.read)
            end
          rescue Exception
            rError = $!
          end
        end

        return rError, rSlaveClientQueue
      end

      # Save the SlaveClient queue for a given SlaveClient info.
      #
      # Parameters:
      # * *iSlaveClientInfo* (<em>map<Symbol,Object></em>): The SlaveClient info
      # * *iSlaveClientQueue* (<em>list<[String,map<ToolID,map<ActionID,list<Parameters>>>]></em>): The SlaveClient queue
      # Return:
      # * _Exception_: An error, or nil if success
      def putSlaveClientQueue(iSlaveClientInfo, iSlaveClientQueue)
        rError = nil

        # Get the hash of this SlaveClient info
        lHash = sprintf('%X', iSlaveClientInfo.hash.abs)
        lQueueFile = "#{@SlaveClientQueuesDir}/#{lHash}.Queue"
        lInfoFile = "#{@SlaveClientQueuesDir}/#{lHash}.Info"
        begin
          if (iSlaveClientQueue.empty?)
            # Delete files
            if (File.exists?(lQueueFile))
              File.unlink(lQueueFile)
            end
            if (File.exists?(lInfoFile))
              File.unlink(lInfoFile)
            end
          else
            if (!File.exists?(lInfoFile))
              File.open(lInfoFile, 'wb') do |oFile|
                oFile.write(Marshal.dump(iSlaveClientInfo))
              end
            end
            File.open(lQueueFile, 'wb') do |oFile|
              oFile.write(Marshal.dump(iSlaveClientQueue))
            end
          end
        rescue Exception
          rError = $!
        end

        return rError
      end

      # Send SlaveActions associated to a SlaveClient Info
      #
      # Parameters:
      # * *iUserID* (_String_): User initiating these SlaveActions
      # * *iSlaveClientInfo* (<em>map<Symbol,Object></em>): The SlaveClient's information
      # * *iSlaveActions* (<em>map<ToolID,map<ActionID,list<Parameters>>></em>): The SlaveActions to perform on this client
      # Return:
      # * _Exception_: An error, or nil in case of success
      def sendSlaveActions(iUserID, iSlaveClientInfo, iSlaveActions)
        rError = nil

        # Gather errors
        # list< String >
        lErrors = []
        # Get the Sender
        @PluginsManager.accessPlugin('Senders', iSlaveClientInfo[:Type]) do |ioSenderPlugin|
          # Create the map of parameters to give the Sender
          lParameters = iSlaveClientInfo.dup
          lParameters.delete(:Type)
          lParameters.delete(:Tools)
          instantiateVars(ioSenderPlugin, lParameters)
          # Handle files transfers according to Providers' specificities
          # map< ToolID, map< ActionID, list< Parameters > > >
          lSlaveActionsForClient = {}
          lErrorEncountered = false
          iSlaveActions.SlaveActions.each do |iToolID, iSlaveActionsList|
            # Parse them to handle file transfers correctly.
            # map< ActionID, list< Parameters > >
            lSlaveActionsList = {}
            iSlaveActionsList.each do |iActionID, iParametersLists|
              lParametersLists = []
              iParametersLists.each do |iParametersList|
                lParametersList = []
                iParametersList.each do |iParameter|
                  if (iParameter.is_a?(TransferFile))
                    lError, lNewData = ioSenderPlugin.prepareFileTransfer(iParameter.LocalFileName)
                    if (lError == nil)
                      lParametersList << lNewData
                    else
                      lErrorEncountered = true
                      lErrors << "Error while preparing file #{iParameter.LocalFileName} to be sent: #{lError}"
                    end
                  else
                    lParametersList << iParameter
                  end
                end
                lParametersLists << lParametersList
              end
              lSlaveActionsList[iActionID] = lParametersLists
            end
            lSlaveActionsForClient[iToolID] = lSlaveActionsList
          end
          if ((!lErrorEncountered) and
              (!lSlaveActionsForClient.empty?))
            # Send them, calling the correct sender, depending on the Slave Client type
            logDebug "Send update (user #{iUserID}) to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect} ..."
            lError = ioSenderPlugin.sendMessage(iUserID, lSlaveActionsForClient)
            if (lError == nil)
              logDebug "... Update sent successfully to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}"
            else
              lErrors << "Unable to send the update to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}: #{lError}"
              logDebug "... Failure to send update to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}: #{lError}"
            end
          end
        end
        if (!lErrors.empty?)
          rError = RuntimeError.new("Several errors encountered:\n#{lErrors.join("\n")}")
        end

        return rError
      end

    end
  
  end

end
