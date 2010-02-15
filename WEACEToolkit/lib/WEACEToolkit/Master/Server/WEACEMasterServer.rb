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

        rOptions.banner = '[-h|--help] [-v|--version] [-d|--debug] [-l|--list] [-e|--detailedlist] [-p|--process <ProcessID> -u|--user <UserID> -- <ProcessParameters>]'
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
              if (@ProcessID != nil)
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
                        # And now call concerned Slave Clients with the returned Slave Actions to perform
                        lErrors = []
                        @MasterServerConfig[:WEACESlaveClients].each do |iSlaveClientInfo|
                          # Gather all the Slave Actions to send to this client
                          # map< ToolID, map< ActionID, list< Parameters > >
                          lSlaveActionsForClient = {}
                          lSlaveActions.SlaveActions.each do |iToolID, iSlaveActionsList|
                            if ((iSlaveClientInfo[:Tools].include?(iToolID)) or
                                (iSlaveClientInfo[:Tools].include?(Tools::All)) or
                                (iToolID == Tools::All))
                              lSlaveActionsForClient[iToolID] = iSlaveActionsList
                            end
                          end
                          if (!lSlaveActionsForClient.empty?)
                            # Send them, calling the correct sender, depending on the Slave Client type
                            # Get the Sender
                            @PluginsManager.accessPlugin('Senders', iSlaveClientInfo[:Type]) do |ioSenderPlugin|
                              # Create the map of parameters to give the Sender
                              lParameters = iSlaveClientInfo.dup
                              lParameters.delete(:Type)
                              lParameters.delete(:Tools)
                              logDebug "Send update to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect} ..."
                              instantiateVars(ioSenderPlugin, lParameters)
                              lError = ioSenderPlugin.sendMessage(@UserID, lSlaveActionsForClient)
                              if (lError == nil)
                                logDebug "... Update sent successfully to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}"
                              else
                                lErrors << "Unable to send the update to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}: #{lError}"
                                logDebug "... Failure to send update to client #{iSlaveClientInfo[:Type]}: #{lParameters.inspect}: #{lError}"
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
              end
            end
          end
        end
        
        return rError
      end

    end
  
  end

end
