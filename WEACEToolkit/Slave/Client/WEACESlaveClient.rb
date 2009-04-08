# Usage:
# ruby -w WEACESlaveClient.rb <UserScriptID> <ScriptID> <ScriptParameters>
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

require "#{File.dirname(__FILE__)}/../../WEACE_Common.rb"

module WEACE

  module Slave
  
    Product_Mediawiki = 'Mediawiki'
    Product_Redmine = 'Redmine'
  
    # This class is used by the configuration file
    class Config
    
      attr_reader :RegisteredAdapters
    
      attr_accessor :LogFile
    
      # Constructor
      def initialize
        # list< [ ProductID, ToolID, list< Parameter > ] >
        @RegisteredAdapters = []
        @LogFile = "#{File.dirname(__FILE__)}/WEACESlaveClient.log"
      end
      
      # Add a new WEACE Slave Client
      #
      # Parameters:
      # * *iType* (_String_): The adapter product type
      # * *iTool* (_String_): The tool for which this adapter adapts
      # * *iParams* (_Parameters_): Following parameters:
      # ** If (iType == Product_Mediawiki):
      # *** *iMediawikiInstallDir* (_String_): The directory where Mediawiki has been installed
      # ** If (iType == Product_Redmine):
      # *** *iMySQLHost* (_String_): The name of the MySQL host
      # *** *iDBName* (_String_): The name of the database of Redmine
      # *** *iDBUser* (_String_): The name of the database user
      # *** *iDBPassword* (_String_): The pasword of the database user
      def addWEACESlaveAdapter(iType, iTool, *iParams)
        @RegisteredAdapters << [ iType, iTool, iParams ]
      end
      
    end
    
    class Client
    
      include WEACE::Logging
    
      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iUserScriptID* (_String_): The user name of the script
      # * *iActions* (<em>map< ToolID, list< [ ActionID, Parameters ] > ></em>): The map of actions to execute
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def execute(iUserScriptID, iActions)
        # Read the configuration file
        begin
          require 'Slave/Client/config/Config.rb'
        rescue RuntimeError
          puts '!!! Unable to load the configuration from file \'config/Config.rb\'. Make sure the file is present and is set in one of the $RUBYLIB paths, or the current path.'
          return false
        end
        lConfig = WEACE::Slave::Config.new
        WEACE::Slave::getWEACESlaveClientConfig(lConfig)
        $LogFile = lConfig.LogFile
        log '== WEACE Slave Client called =='
        log "* User: #{iUserScriptID}"
        log "* #{iActions.size} tools to update:"
        iActions.each do |iToolID, iActionsList|
          log "** For #{iToolID}: #{iActionsList.size} actions:"
          iActionsList.each do |iActionInfo|
            iActionID, iActionParameters = iActionInfo
            log "*** #{iActionID} (#{iActionParameters.inspect})"
          end
        end
        log "#{lConfig.RegisteredAdapters.size} adapters configuration:"
        # map< ToolID, [ ProductID, Parameters ] >
        lAdapterPerTool = {}
        lIdx = 0
        lConfig.RegisteredAdapters.each do |iAdapterInfo|
          iProductID, iToolID, iParameters = iAdapterInfo
          log "* Adapter n.#{lIdx}:"
          log "** Product: #{iProductID}"
          log "** Tool: #{iToolID}"
          log "** Parameters: #{iParameters.inspect}"
          lIdx += 1
          # Profit from this loop to index adapters per ToolID
          lAdapterPerTool[iToolID] = [ iProductID, iParameters ]
        end
        # For each tool having an action, call all the adapters for this tool
        lErrors = []
        iActions.each do |iToolID, iActionsList|
          # For each adapter adapting iToolID
          lAdapterPerTool[iToolID].each do |iAdapterInfo|
            iProductID, iProductParameters = iAdapterInfo
            # For action to give to this adapter
            iActionsList.each do |iActionInfo|
              iActionID, iActionParameters = iActionInfo
              log 'Executing action on a product using an adapter:'
              log "* Action: #{iActionID}"
              log "* Action parameters: #{iActionParameters.inspect}"
              log "* Product: #{iProductID}"
              log "* Product config: #{iProductParameters.inspect}"
              log "* Tool: #{iToolID}"
              log "* Adapter: #{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
              log "* Adapter method: #{iProductID}::#{iToolID}::#{iActionID}::execute"
              # Require the correct adapter file for the given action
              begin
                require "Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                begin
                  lParameters = iProductParameters + iActionParameters
                  eval("#{iProductID}::#{iToolID}::#{iActionID}::execute(iUserScriptID, *lParameters)")
                  log 'Adapter completed action without error.'
                rescue RuntimeError
                  logErr "Error while executing Adapter #{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                  lErrors << "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                end
              rescue RuntimeError
                logErr "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                lErrors << "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
              end
            end
          end
        end
        if (!lErrors.empty?)
          logErr 'Several errors encountered:'
          logErr lErrors.join("\n")
          return false
        end
        log '== WEACE Slave Client completed successfully =='
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
    if (WEACE::Slave::Client.new.execute(lUserScriptID, lScriptID, lScriptParameters))
      exit 0
    else
      exit 1
    end
  end
end
