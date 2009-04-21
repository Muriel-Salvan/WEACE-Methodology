# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'date'
require 'fileutils'

module WEACE

  # Class encapsulating an installed Component's description
  class InstalledComponentDescription
  
    # The description
    #   String
    attr_accessor :Description
    
    # The date of install
    #   Date
    attr_accessor :Date
    
    # The version installed
    #   String
    attr_accessor :Version
    
    # The author
    #   String
    attr_accessor :Author
    
  end
  
  # Actions to be performed by Slave Clients
  # For the Tickets Manager:
  Action_Ticket_AddLinkToTask = 'Ticket_AddLinkToTask'
  Action_Ticket_RejectDuplicate = 'Ticket_RejectDuplicate'
  # For the Project Manager:
  Action_Task_AddLinkToTicket = 'Task_AddLinkToTicket'
  
  # Types of tools to update
  # All tools, no matter what is installed
  Tools_All = 'All'
  # Wiki
  Tools_Wiki = 'Wiki'
  # Tickets Tracker
  Tools_TicketTracker = 'TicketTracker'
  # Project Manager
  Tools_ProjectManager = 'ProjectManager'
  
  # Class containing info for serialized method calls
  class MethodCallInfo

    #  String: LogFile
    attr_accessor :LogFile
    
    #  list<String>: Load path
    attr_accessor :LoadPath
    
    #  list<String>: List of files to require
    attr_accessor :RequireFiles
    
    #  String: Serialized MethodDetails
    # It is stored serialized as to unserialize it we first need to unserialize the RequireFiles
    attr_accessor :SerializedMethodDetails
    
    class MethodDetails

      #  Object: Object to call the function on,
      attr_accessor :Object
    
      #  String: Function name to call,
      attr_accessor :FunctionName
    
      #  list<Object>: Parameters,
      attr_accessor :Parameters
      
    end
    
  end

  # Various methods used broadly
  module Toolbox

    # Check that an instance variable has been correctly instantiated, and give a good looking exception otherwise.
    #
    # Parameters:
    # * *iVariable* (_Symbol_): The variable we are looking for.
    # * *iDescription* (_String_): The description of this variable. This will appear in the eventual error message.
    def checkVar(iVariable, iDescription)
      if (!self.instance_variable_defined?(iVariable))
        logExc "Variable #{iVariable} (#{iDescription}) not set. Check your configuration."
      end
    end

    # Store a map of variable names and their corresponding values as instance variables of a given class
    #
    # Parameters:
    # * *iObject* (_Object_): Object where we want to instantiate those variables
    # * *iVars* (<em>map<Symbol,Object></em>): The map of variables and their values
    def instantiateVars(iObject, iVars)
      iVars.each do |iVariable, iValue|
        # Define the setter if needed
        if (!iObject.class.method_defined?("setInstanceVar_#{iVariable}"))
          iObject.class.module_eval("
def setInstanceVar_#{iVariable}(iValue)
  @#{iVariable} = iValue
end
")
        end
        # Set the value
        eval("iObject.setInstanceVar_#{iVariable}(iValue)")
      end
    end
  
    # Dump HTML header
    #
    # Parameters:
    # * *iTitle* (_String_): Title of the header
    def dumpHeader_HTML(iTitle)
      puts '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
      puts '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">'
      puts "  <title>#{iTitle}</title>"
      puts '  <style>'
      puts '    body {'
      puts '      font-family: Trebuchet MS,Georgia,"Times New Roman",serif;'
      puts '      color:#303030;'
      puts '      margin:10px;'
      puts '    }'
      puts '    h1 {'
      puts '      font-size:1.5em;'
      puts '    }'
      puts '    h2 {'
      puts '      font-size:1.2em;'
      puts '    }'
      puts '    h3 {'
      puts '      font-size:1.0em;'
      puts '    }'
      puts '    h4 {'
      puts '      font-size:0.9em;'
      puts '    }'
      puts '    p {'
      puts '      font-size:0.8em;'
      puts '    }'
      puts '  </style>'
      puts '<body>'
    end

    # Dump HTML footer
    def dumpFooter_HTML
      puts '</body>'
      puts '</html>'
    end

    # Execute some Ruby code in the MySQL environment.
    # The code executed has to be in a method named executeSQL that takes the SQL connection as a first parameter.
    #
    # Parameters:
    # * *iMySQLHost* (_String_): The name of the MySQL host
    # * *iDBName* (_String_): The name of the database of Redmine
    # * *iDBUser* (_String_): The name of the database user
    # * *iDBPassword* (_String_): The password of the database user
    # * *Parameters* (<em>list<String></em>): Additional parameters
    def execMySQL(iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
      # Go on
      require 'rubygems'
      require 'mysql'
      # Connect to the db
      lMySQL = Mysql::new(iMySQLHost, iDBUser, iDBPassword, iDBName)
      # Create a transaction
      lMySQL.query("start transaction")
      begin
        executeSQL(lMySQL, *iParameters)
        lMySQL.query("commit")
      rescue RuntimeError
        lMySQL.query("rollback")
        raise
      end
    end
    
    # Execute a command in another Ruby session, executing some Shell commands before invocation.
    #
    # Parameters:
    # * *iShellCmd* (_String_): Shell command to invoke before Ruby
    # * *iObject* (_Object_): Object that will have a function to call in the new session
    # * *iFunctionName* (_String_): Function name to call on the object
    # * *Parameters*: Remaining parameters
    def execCmdOtherSession(iShellCmd, iObject, iFunctionName, *iParameters)
      # Create an object that we will serialize, containing all needded information for the session
      lInfo = MethodCallInfo.new
      lInfo.LogFile = $LogFile
      lInfo.RequireFiles = $".clone
      lInfo.LoadPath = $LOAD_PATH.clone
      lMethodDetails = MethodCallInfo::MethodDetails.new
      lMethodDetails.Parameters = iParameters
      lMethodDetails.FunctionName = iFunctionName
      lMethodDetails.Object = iObject
      lInfo.SerializedMethodDetails = Marshal.dump(lMethodDetails)
      # Dump this object in a temporary file
      require 'tmpdir'
      lFileName = "#{Dir.tmpdir}/WEACE_#{Thread.object_id}_Call"
      File.open(lFileName, 'w') do |iFile|
        iFile.write(Marshal.dump(lInfo))
      end
      # For security reasons, ensure that only us can read this file. It can contain passwords.
      require 'fileutils'
      FileUtils.chmod(0700, lFileName)
      # Call the other session
      execCmd("#{iShellCmd}; ruby -w #{$WEACEToolkitDir}/Execute.rb #{lFileName} 2>&1")
    end
  
    # Execute a command
    #
    # Parameters:
    # * *iCmd* (_String_): The command to execute
    def execCmd(iCmd)
      lOutput = `#{iCmd}`
      lErrorCode = $?
      if (lErrorCode != 0)
        logExc RuntimeError, "Error while running command \"#{iCmd}\". Here is the output:\n#{lOutput}."
      end
    end
    
    # Modify a file in a safe way (exception protected, keep copy of original...).
    # It inserts or replaces some of the content of this file, between 2 markers (1 begin and 1 end markers).
    #
    # Parameters:
    # * *iFileName* (_String_): The file to modify
    # * *iBeginMarker* (_RegExp_): The begin marker (can be nil if it represents the beginning of the file)
    # * *iNewLines* (_String_): The text to insert between the markers (can be nil if it represents the end of the file)
    # * *iEndMarker* (_RegExp_): The end marker
    # * *iOptions* (_Hash_): Additional parameters: [ optional = {} ]
    # ** *:Replace* (_Boolean_): Do we completely replace the text between the markers ?
    # ** *:NoBackup* (_Boolean_): Do we skip backuping the file ?
    # ** *:CheckMatch* (<em>list<Object></em>): List of String or RegExp used to check if the new content is already present. If not specified, an exact match on iNewLines is performed.
    def modifyFile(iFileName, iBeginMarker, iNewLines, iEndMarker, iOptions = {})
      log "Modify file #{iFileName} ..."
      if (iOptions[:NoBackup] == nil)
        # First, copy the file if the backup does not already exist (avoid overwriting the backup with a modified file when invoked several times)
        lBackupName = "#{iFileName}.WEACEBackup"
        if (!File.exists?(lBackupName))
          FileUtils.cp(iFileName, lBackupName)
        end
      end
      # Read the file
      lContent = nil
      File.open(iFileName, 'r') do |iFile|
        lContent = iFile.readlines
      end
      # Find the 2 markers among the file
      lIdxBegin = nil
      if (iBeginMarker == nil)
        lIdxBegin = -1
      end
      lIdxEnd = nil
      if (iEndMarker == nil)
        lIdxEnd = lContent.size
      end
      lIdx = 0
      lContent.each do |iLine|
        if ((lIdxBegin == nil) and
            (iLine.match(iBeginMarker) != nil))
          # We found the beginning
          lIdxBegin = lIdx
          if (lIdxEnd != nil)
            # We already know the end is at the end
            break
          end
        elsif ((lIdxBegin != nil) and
               (lIdxEnd == nil) and
               (iLine.match(iEndMarker) != nil))
          # We found the end
          lIdxEnd = lIdx
          break
        end
        lIdx += 1
      end
      # If we didn't find both of them, stop it
      if (lIdxBegin == nil)
        logExc "Unable to find beginning mark /#{iBeginMarker}/ in file #{iFileName}. Aborting modification."
      elsif (lIdxEnd == nil)
        logExc "Unable to find ending mark /#{iEndMarker}/ in file #{iFileName}. Aborting modification."
      else
        # Ensure that new lines separate the content of iNewLines, and each line terminates with a \n
        lNewLines = nil
        if (iNewLines.is_a?(String))
          lNewLines = iNewLines.split("\n")
        else
          lNewLines = iNewLines.join("\n").split("\n")
        end
        (0 .. lNewLines.size-1).each do |iIdx|
          if (lNewLines[iIdx][-1..-1] != "\n")
            lNewLines[iIdx] += "\n"
          end
        end
        # Check if the new content is not already in lContent (starting from lIdxBegin)
        lMatchLines = lNewLines
        if (iOptions[:CheckMatch] != nil)
          lMatchLines = iOptions[:CheckMatch]
        end
        lFound = false
        if (lIdxBegin < lIdxEnd-lMatchLines.size)
          (lIdxBegin+1 .. lIdxEnd-lMatchLines.size).each do |iIdx|
            # Validate that each line equals or matches
            lFound = true
            (0 .. lMatchLines.size-1).each do |iIdxMatch|
              if (((lMatchLines[iIdxMatch].is_a?(String)) and
                   (lContent[iIdx+iIdxMatch] != lMatchLines[iIdxMatch])) or
                  ((lMatchLines[iIdxMatch].is_a?(Regexp)) and 
                   (lContent[iIdx+iIdxMatch].match(lMatchLines[iIdxMatch]) == nil)))
                # It differs
                lFound = false
                break
              end
            end
            if (lFound)
              break
            end
          end
        end
        if (lFound)
          # Already here
          logWarn "File #{iFileName} already contains modifications. It will be left unchanged."
        else
          # Modify the content in memory
          if (iOptions[:Replace] == true)
            # Erase everything between markers
            if (lIdxBegin == -1)
              lContent = lContent[lIdxEnd..-1]
            else
              lContent = lContent[0..lIdxBegin] + lContent[lIdxEnd..-1]
            end
            lIdxEnd = lIdxBegin + 1
          end
          # Insert at lIdxEnd position
          lContent.insert(lIdxEnd, lNewLines)
          # Write the file
          begin
            File.open(iFileName, 'w') do |iFile|
              iFile << lContent
            end
          rescue Exception
            # Revert the file content
            FileUtils.cp("#{iFileName}.WEACEBackup", iFileName)
            logExc RuntimeError, "Exception while writing file #{iFileName}: #{$!}. The file content has been reverted back to original."
          end
          log "File #{iFileName} modified successfully."
        end
      end
      
    end
    
  end

  module Logging
  
    # Log something
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def log(iMessage)
      logInternal("[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - #{iMessage}")
    end

    # Log something as an error
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def logErr(iMessage)
      logInternal("[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - !!! ERROR !!! - #{iMessage}")
    end
    
    # Log something as an exception
    #
    # Parameters:
    # * *iError* (_Exception_): The exception to raise
    # * *iMessage* (_String_): The message to log
    def logExc(iError, iMessage)
      logErr iMessage
      raise iError, iMessage
    end
    
    # Log something as a warning
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def logWarn(iMessage)
      logInternal("[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - ! WARNING ! - #{iMessage}")
    end
    
    # Log something (internal use only)
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def logInternal(iMessage)
      if ($LogIO != nil)
        $LogIO.puts iMessage
      end
      if ($LogFile != nil)
        File.open($LogFile, 'a') do |iFile|
          iFile << "#{iMessage}\n"
        end
      end
    end

  end

end
