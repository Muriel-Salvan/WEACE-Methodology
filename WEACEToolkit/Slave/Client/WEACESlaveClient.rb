# Usage:
# ruby -w WEACESlaveClient.rb <UserScriptID> [ -t <ToolID> [ -a <ActionID> <ActionParameters> ]* ]*
#
# <ActionParameters> depend on <ActionID>. Here are the possible <ActionID> values and their corresponding possible <ActionParameters>:
# * Ticket_AddLinkToTask <TicketID> <TaskID>
# * Ticket_RejectDuplicate <MasterTicketID> <SlaveTicketID>
#
# Example: ruby -w WEACESlaveClient.rb Scripts_Validator -t TicketTracker -a Ticket_RejectDuplicate 123 456 -a Ticket_AddLinkToTask 789 234
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
      # * *iParams* (<em>map<Symbol,Object></em>): Additional parameters (refer to the documentation of Adapters to know parameters)
      def addWEACESlaveAdapter(iType, iTool, iParams)
        @RegisteredAdapters << [ iType, iTool, iParams ]
      end
      
    end
    
    class Client
    
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
      # * *iUserScriptID* (_String_): The user name of the script
      # * *iActions* (<em>map< ToolID, list< [ ActionID, Parameters ] > ></em>): The map of actions to execute
      # Return:
      # * _Boolean_: Has the operation completed successfully ?
      def execute(iUserScriptID, iActions)
        # Read the configuration file
        begin
          require 'Slave/Client/config/Config.rb'
        rescue Exception
          puts '!!! Unable to load the configuration from file \'config/Config.rb\'. Make sure the file is present and is set in one of the $RUBYLIB paths, or the current path.'
          return false
        end
        lConfig = WEACE::Slave::Config.new
        WEACE::Slave::getWEACESlaveClientConfig(lConfig)
        setLogFile(lConfig.LogFile)
        logInfo '== WEACE Slave Client called =='
        logDebug "* User: #{iUserScriptID}"
        logDebug "* #{iActions.size} tools to update:"
        iActions.each do |iToolID, iActionsList|
          logDebug "** For #{iToolID}: #{iActionsList.size} actions:"
          iActionsList.each do |iActionInfo|
            iActionID, iActionParameters = iActionInfo
            logDebug "*** #{iActionID} (#{iActionParameters.inspect})"
          end
        end
        logDebug "#{lConfig.RegisteredAdapters.size} adapters configuration:"
        # map< ToolID, list< [ ProductID, Parameters ] > >
        lAdapterPerTool = {}
        lIdx = 0
        lConfig.RegisteredAdapters.each do |iAdapterInfo|
          iProductID, iToolID, iParameters = iAdapterInfo
          logDebug "* Adapter n.#{lIdx}:"
          logDebug "** Product: #{iProductID}"
          logDebug "** Tool: #{iToolID}"
          logDebug "** Parameters: #{iParameters.inspect}"
          lIdx += 1
          # Profit from this loop to index adapters per ToolID
          if (lAdapterPerTool[iToolID] == nil)
            lAdapterPerTool[iToolID] = []
          end
          lAdapterPerTool[iToolID] << [ iProductID, iParameters ]
        end
        # For each tool having an action, call all the adapters for this tool
        # Require the file registering WEACE Slave Adapters
        require 'Slave/Client/InstalledWEACESlaveComponents.rb'
        # Get the list
        lInstalledAdapters = WEACE::Slave::getInstalledAdapters
        lErrors = []
        iActions.each do |iToolID, iActionsList|
          # For each adapter adapting iToolID
          lAdapterPerTool[iToolID].each do |iAdapterInfo|
            iProductID, iProductParameters = iAdapterInfo
            # For each action to give to this adapter
            iActionsList.each do |iActionInfo|
              iActionID, iActionParameters = iActionInfo
              # First check that iProductID.iToolID.iActionID is registered
              lAdapterFound = false
              if ((lInstalledAdapters[iProductID] != nil) and
                  (lInstalledAdapters[iProductID][iToolID] != nil))
                lInstalledAdapters[iProductID][iToolID].each do |iAdapterInfo|
                  iScriptID, iDate, iDescription = iAdapterInfo
                  if (iScriptID == iActionID)
                    lAdapterFound = true
                  end
                end
              end
              if (lAdapterFound)
                logDebug 'Executing action on a product using an adapter:'
                logDebug "* Action: #{iActionID}"
                logDebug "* Action parameters: #{iActionParameters.inspect}"
                logDebug "* Product: #{iProductID}"
                logDebug "* Product config: #{iProductParameters.inspect}"
                logDebug "* Tool: #{iToolID}"
                logDebug "* Adapter: #{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                logDebug "* Adapter method: #{iProductID}::#{iToolID}::#{iActionID}::execute"
                # Require the correct adapter file for the given action
                begin
                  require "Slave/Adapters/#{iProductID}/#{iToolID}/#{iActionID}.rb"
                  begin
                    lAdapter = eval("#{iProductID}::#{iToolID}::#{iActionID}.new")
                    instantiateVars(lAdapter, iProductParameters)
                    lAdapter.execute(iUserScriptID, *iActionParameters)
                    logDebug 'Adapter completed action without error.'
                  rescue RuntimeError
                    logErr "Error while executing Adapter #{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb: #{$!}."
                    logErr $!.backtrace.join("\n")
                    lErrors << "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                  end
                rescue RuntimeError
                  logErr "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb: #{$!}."
                  logErr $!.backtrace.join("\n")
                  lErrors << "Unable to load the Slave Adapter Slave/Adapters/#{iProductID}/#{iToolID}/#{iProductID}_#{iToolID}_#{iActionID}.rb"
                end
              else
                logWarn "Adapter #{iProductID}.#{iToolID}.#{iActionID} has not been registered on this WEACE Slave Provider. The action has been ignored: #{iActionID} (#{iActionParameters})."
              end
            end
          end
        end
        if (!lErrors.empty?)
          logErr 'Several errors encountered:'
          logErr lErrors.join("\n")
          return false
        end
        logInfo '== WEACE Slave Client completed successfully =='
        return true
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lUserScriptID = ARGV[0..0]
  lActions = {}
  lInvalid = false
  lBeginNewTool = false
  lCurrentTool = nil
  lBeginNewAction = false
  lIdxCurrentAction = nil
  ARGV[1..-1].each do |iArg|
    case iArg
    when '-t'
      if ((lBeginNewAction) or
          ((lCurrentTool != nil) and
           (lIdxCurrentAction == nil)))
        lInvalid = true
      else
        lBeginNewTool = true
        lIdxCurrentAction = nil
      end
    when '-a'
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
        lInvalid = true
      end
    end
  end
  if ((lUserScriptID == nil) or
      (lInvalid))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w WEACESlaveClient.rb <UserScriptID> [ -t <ToolID> [ -a <ActionID> <ActionParameters> ]* ]*'
    puts ''
    puts '<ActionParameters> depend on <ActionID>. Here are the possible <ActionID> values and their corresponding possible <ActionParameters>:'
    puts '* Ticket_AddLinkToTask <TicketID> <TaskID>'
    puts '* Ticket_RejectDuplicate <MasterTicketID> <SlaveTicketID>'
    puts ''
    puts 'Example: ruby -w WEACESlaveClient.rb Scripts_Validator -t TicketTracker -a Ticket_RejectDuplicate 123 456 -a Ticket_AddLinkToTask 789 234'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    if (WEACE::Slave::Client.new.execute(lUserScriptID, lActions))
      exit 0
    else
      exit 1
    end
  end
end
