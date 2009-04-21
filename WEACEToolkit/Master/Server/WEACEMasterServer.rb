# Usage:
# ruby -w WEACEMasterServer.rb <UserScriptID> <ScriptID> <ScriptParameters>
#
# <ScriptParameters> depend on <ScriptID>. Here are the possible <ScriptID> values and their corresponding possible <ScriptParameters>:
# * Task_LinkTicket <TicketID> <TaskID>
# * Ticket_CloseDuplicate <MasterTicketID> <SlaveTicketID>
# * Plan_PublishProjects
# * Dev_Commit <Comment> -t [ <TaskID> ]* -f [ <FileName> ]*
# * Dev_Release <BranchID> <Comment>
# * Dev_NewBranch <BranchID> <Comment>
#
# Example: ruby -w WEACEMasterServer.rb Scripts_Validator Ticket_CloseDuplicate 123 456
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Master
  
    # Types of the clients
    # Local: The WEACE Slave Client is present in this host
    ClientType_Local = 'Local'
    # ExternalCGIPost: The WEACE Slave Client is present behind a CGI script accessible via an URL
    ClientType_ExternalCGIPost = 'ExternalCGIPost'
    
    # This class is used by the configuration file
    class Config
    
      attr_reader :RegisteredClients
      
      attr_accessor :LogFile
    
      # Constructor
      def initialize
        # list< [ ClientType, list< ToolID >, list< Parameter > ] >
        @RegisteredClients = []
        @LogFile = "#{File.dirname(__FILE__)}/WEACEMasterServer.log"
      end
      
      # Add a new WEACE Slave Client
      #
      # Parameters:
      # * *iType* (_String_): The client type
      # * *iTools* (<em>list<String></em>): The list of tools installed on this client
      # * *iParams* (<em>map<Symbol,Object></em>): Additional parameters (refer to the documentation of Senders to know parameters)
      def addWEACESlaveClient(iType, iTools, iParams)
        @RegisteredClients << [ iType, iTools, iParams ]
      end
      
    end
    
    # This class is used by the processing scripts to give actions to Slave Clients
    class SlaveActions
    
      attr_reader :SlaveActions
    
      # Constructor
      def initialize
        # map< ToolID, list< [ ActionID, Parameters ] > >
        @SlaveActions = {}
      end
    
      # Constructor
      #
      # Parameters:
      # * *iToolID* (_String_): The tool ID (check values in ../../WEACE_Common.rb)
      # * *iActionID* (_String_): The action ID (check values in ../../WEACE_Common.rb)
      # * *iParameters* (<em>list<Param></em>): Additional parameters to give the Slave Client
      def addSlaveAction(iToolID, iActionID, *iParameters)
        if (@SlaveActions[iToolID] == nil)
          @SlaveActions[iToolID] = []
        end
        @SlaveActions[iToolID] << [ iActionID, iParameters ]
      end
      
    end

    class Server
    
      include WEACE::Logging
    
      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iUserScriptID* (_String_): The user name of the script
      # * *iScriptID* (_String_): The script to execute
      # * *iScriptParameters* (<em>list<String></em>): Additional parameters to give the script
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def execute(iUserScriptID, iScriptID, iScriptParameters)
        # Read the configuration file
        begin
          require 'Master/Server/config/Config.rb'
        rescue Exception
          puts '!!! Unable to load the configuration from file \'config/Config.rb\'. Make sure the file is present and is set in one of the $RUBYLIB paths, or the current path.'
          return false
        end
        lConfig = WEACE::Master::Config.new
        WEACE::Master::getWEACEMasterServerConfig(lConfig)
        $LogFile = lConfig.LogFile
        $LogIO = $stdout
        log '== WEACE Master Server called =='
        log "* User: #{iUserScriptID}"
        log "* Script: #{iScriptID}"
        log "* Parameters: #{iScriptParameters.inspect}"
        log "#{lConfig.RegisteredClients.size} clients configuration:"
        lIdx = 0
        lConfig.RegisteredClients.each do |iSlaveClientInfo|
          iClientType, iClientTools, iClientParameters = iSlaveClientInfo
          log "* Client n.#{lIdx}:"
          log "** Type: #{iClientType}"
          log "** Parameters: #{iClientParameters.inspect}"
          log "** #{iClientTools.size} tools are installed on this client:"
          iClientTools.each do |iToolID|
            log "*** #{iToolID}"
          end
          lIdx += 1
        end
        # First check that our requires are indeed present
        begin
          require "Master/Server/Process_#{iScriptID}.rb"
        rescue RuntimeError
          logErr "Unable to load the process corresponding to script #{iScriptID}"
          return false
        end
        lConfig.RegisteredClients.each do |iSlaveClientInfo|
          iClientType, iClientTools, iClientParameters = iSlaveClientInfo
          begin
            require "Master/Server/Sender_#{iClientType}.rb"
          rescue RuntimeError
            logErr "Unable to load the sender library corresponding to client type #{iClientType}"
            return false
          end
        end
        # Call the corresponding script, and get its summary of actions to propagate to the Slave Clients.
        lSlaveActions = SlaveActions.new
        processScript(lSlaveActions, *iScriptParameters)
        # And now call concerned Slave Clients with the returned Slave Actions to perform
        lErrors = []
        lConfig.RegisteredClients.each do |iSlaveClientInfo|
          iClientType, iClientTools, iClientParameters = iSlaveClientInfo
          # Gather all the Slave Actions to send to this client
          # map< ToolID, list< ActionID, Parameters > >
          lSlaveActionsForClient = {}
          lSlaveActions.SlaveActions.each do |iToolID, iSlaveActionsList|
            if ((iClientTools.include?(iToolID)) or
                (iClientTools.include?(Tools_All)))
              lSlaveActionsForClient[iToolID] = iSlaveActionsList
            end
          end
          if (!lSlaveActionsForClient.empty?)
            # Send them, calling the correct sender, depending on the Slave Client type
            lSender = eval("Sender_#{iClientType}.new")
            log "Send update to client #{iClientType}: #{iClientParameters.inspect} ..."
            instantiateVars(lSender, iClientParameters)
            lSuccess = lSender.sendMessage(iUserScriptID, lSlaveActionsForClient)
            if (!lSuccess)
              lErrors << "Unable to send the update to client #{iClientType}: #{iClientParameters.inspect}"
              log "... Failure to send update to client #{iClientType}: #{iClientParameters.inspect}"
            else
              log "... Update sent successfully to client #{iClientType}: #{iClientParameters.inspect}"
            end
          end
        end
        if (!lErrors.empty?)
          logErr 'Several errors encountered:'
          logErr lErrors.join("\n")
          return false
        end
        log '== WEACE Master Server completed successfully =='
        return true
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lUserScriptID, lScriptID = ARGV[0..1]
  lScriptParameters = ARGV[2..-1]
  if ((lUserScriptID == nil) or
      (lScriptID == nil) or
      (lScriptParameters == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w WEACEMasterServer.rb <UserScriptID> <ScriptID> <ScriptParameters>'
    puts ''
    puts '<ScriptParameters> depend on <ScriptID>. Here are the possible <ScriptID> values and their corresponding possible <ScriptParameters>:'
    puts '* Task_LinkTicket <TicketID> <TaskID>'
    puts '* Ticket_CloseDuplicate <MasterTicketID> <SlaveTicketID>'
    puts '* Plan_PublishProjects'
    puts '* Dev_Commit <Comment> -t [ <TaskID> ]* -f [ <FileName> ]*'
    puts '* Dev_Release <BranchID> <Comment>'
    puts '* Dev_NewBranch <BranchID> <Comment>'
    puts ''
    puts 'Example: ruby -w WEACEMasterServer.rb Scripts_Validator Ticket_CloseDuplicate 123 456'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    if (WEACE::Master::Server.new.execute(lUserScriptID, lScriptID, lScriptParameters))
      exit 0
    else
      exit 1
    end
  end
end
