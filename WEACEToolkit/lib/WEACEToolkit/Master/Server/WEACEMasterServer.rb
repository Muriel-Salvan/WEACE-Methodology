# Called using WEACEExecute.rb using the following parameters:
# <UserScriptID> <ScriptID> <ScriptParameters>
#
# <ScriptParameters> depend on <ScriptID>. Here are the possible <ScriptID> values and their corresponding possible <ScriptParameters>:
# * Task_LinkTicket <TicketID> <TaskID>
# * Ticket_CloseDuplicate <MasterTicketID> <SlaveTicketID>
# * Plan_PublishProjects
# * Dev_Commit <Comment> -t [ <TaskID> ]* -f [ <FileName> ]*
# * Dev_Release <BranchID> <Comment>
# * Dev_NewBranch <BranchID> <Comment>
#
# Example: ruby -w WEACEExecute.rb MasterServer Scripts_Validator Ticket_CloseDuplicate 123 456
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/WEACE_Common'

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
    
      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): The list of parameters
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def execute(iParameters)
        rSuccess = true

        # Parse parameters
        lUserScriptID, lScriptID = iParameters[0..1]
        lScriptParameters = iParameters[2..-1]
        if ((lUserScriptID == nil) or
            (lScriptID == nil) or
            (lScriptParameters == nil))
          # Print some usage
          logErr "Incorrect parameters: \"#{iParameters.join(' ')}\".
Signature: <UserScriptID> <ScriptID> <ScriptParameters>

<ScriptParameters> depend on <ScriptID>. Here are the possible <ScriptID> values and their corresponding possible <ScriptParameters>:
* Task_LinkTicket <TicketID> <TaskID>
* Ticket_CloseDuplicate <MasterTicketID> <SlaveTicketID>
* Plan_PublishProjects
* Dev_Commit <Comment> -t [ <TaskID> ]* -f [ <FileName> ]*
* Dev_Release <BranchID> <Comment>
* Dev_NewBranch <BranchID> <Comment>

Example: Scripts_Validator Ticket_CloseDuplicate 123 456

Check http://weacemethod.sourceforge.net for details."
          rSuccess = false
        else
          # Read the configuration file
          begin
            require 'WEACEToolkit/Master/Server/config/Config'
          rescue Exception
            logExc $!, '!!! Unable to load the configuration from file \'config/Config.rb\'. Make sure the file is present and is set in one of the $RUBYLIB paths, or the current path.'
            rSuccess = false
          end
          if (rSuccess)
            lConfig = WEACE::Master::Config.new
            WEACE::Master::getWEACEMasterServerConfig(lConfig)
            setLogFile(lConfig.LogFile)
            logInfo '== WEACE Master Server called =='
            logDebug "* User: #{lUserScriptID}"
            logDebug "* Script: #{lScriptID}"
            logDebug "* Parameters: #{lScriptParameters.inspect}"
            logDebug "#{lConfig.RegisteredClients.size} clients configuration:"
            lIdx = 0
            lConfig.RegisteredClients.each do |iSlaveClientInfo|
              iClientType, iClientTools, iClientParameters = iSlaveClientInfo
              logDebug "* Client n.#{lIdx}:"
              logDebug "** Type: #{iClientType}"
              logDebug "** Parameters: #{iClientParameters.inspect}"
              logDebug "** #{iClientTools.size} tools are installed on this client:"
              iClientTools.each do |iToolID|
                logDebug "*** #{iToolID}"
              end
              lIdx += 1
            end
            # First check that our requires are indeed present
            begin
              require "WEACEToolkit/Master/Server/Process_#{lScriptID}"
            rescue RuntimeError
              logErr "Unable to load the process corresponding to script #{lScriptID}"
              return false
            end
            lConfig.RegisteredClients.each do |iSlaveClientInfo|
              iClientType, iClientTools, iClientParameters = iSlaveClientInfo
              begin
                require "WEACEToolkit/Master/Server/Sender_#{iClientType}"
              rescue RuntimeError
                logErr "Unable to load the sender library corresponding to client type #{iClientType}"
                return false
              end
            end
            # Call the corresponding script, and get its summary of actions to propagate to the Slave Clients.
            lSlaveActions = SlaveActions.new
            processScript(lSlaveActions, *lScriptParameters)
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
                logDebug "Send update to client #{iClientType}: #{iClientParameters.inspect} ..."
                instantiateVars(lSender, iClientParameters)
                lSuccess = lSender.sendMessage(iUserScriptID, lSlaveActionsForClient)
                if (!lSuccess)
                  lErrors << "Unable to send the update to client #{iClientType}: #{iClientParameters.inspect}"
                  logDebug "... Failure to send update to client #{iClientType}: #{iClientParameters.inspect}"
                else
                  logDebug "... Update sent successfully to client #{iClientType}: #{iClientParameters.inspect}"
                end
              end
            end
            if (!lErrors.empty?)
              logErr 'Several errors encountered:'
              logErr lErrors.join("\n")
              rSuccess = false
            end
          end
        end
        return rSuccess
      end
      
    end
  
  end

end
