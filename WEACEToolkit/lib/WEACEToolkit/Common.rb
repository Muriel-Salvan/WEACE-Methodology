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

require 'WEACEToolkit/TerminalSize'
require 'WEACEToolkit/Tools'
require 'WEACEToolkit/Actions'
require 'WEACEToolkit/Errors'

module WEACE

  # Class containing info for serialized method calls
  # TODO: Check if we can remove it.
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
  module Common

    # Get the command line parameters to give the WEACE Slave Client corresponding to a given set of Actions to execute
    #
    # Parameters:
    # * *iUserScriptID* (_String_): The user ID of the script
    # * *iSlaveActions* (<em>map< ToolID, map< ActionID, list < Parameters > > ></em>): The map of actions to send to the Slave Client
    # Return:
    # * <em>list<String></em>: Corresponding command line parameters
    def getSlaveClientParamsFromActions(iUserScriptID, iSlaveActions)
      rParameters = [ '--user', iUserScriptID ]

      iSlaveActions.each do |iToolID, iActionsInfo|
        rParameters += [ '--tool', iToolID ]
        iActionsInfo.each do |iActionID, iParametersList|
          iParametersList.each do |iParameters|
            rParameters += [ '--action', iActionID ]
            rParameters += iParameters
          end
        end
      end

      return rParameters
    end

    # Setup installation plugins.
    # This sets the @PluginsManager variable.
    # Prerequisite: setupWEACEDirs has to be called before.
    def setupInstallPlugins
      require 'rUtilAnts/Plugins'
      @PluginsManager = RUtilAnts::Plugins::PluginsManager.new
      parseMasterPlugins
      parseSlavePlugins
    end

    # Parse Master plugins
    def parseMasterPlugins
      # Master Providers
      parseWEACEPluginsFromDir('Master/Providers', "#{@WEACELibDir}/Install/Master/Providers", 'WEACEInstall::Master::Providers')
      # Master Server
      parseWEACEPluginsFromDir('Master/Server', "#{@WEACELibDir}/Install/Master/Server", 'WEACEInstall::Master')
      # Master Adapters
      # Master Products
      parseWEACEPluginsFromDir('Master/Products', "#{@WEACELibDir}/Install/Master/Adapters", 'WEACEInstall::Master::Adapters')
      Dir.glob("#{@WEACELibDir}/Install/Master/Adapters/*").each do |iProductDirName|
        if (File.directory?(iProductDirName))
          lProductID = File.basename(iProductDirName)
          # Master Processes
          parseWEACEPluginsFromDir("Master/Processes/#{lProductID}", "#{@WEACELibDir}/Install/Master/Adapters/#{lProductID}", "WEACEInstall::Master::Adapters::#{lProductID}")
        end
      end
    end

    # Parse Slave plugins
    def parseSlavePlugins
      # Slave Providers
      parseWEACEPluginsFromDir('Slave/Providers', "#{@WEACELibDir}/Install/Slave/Providers", 'WEACEInstall::Slave::Providers')
      # Slave Client
      parseWEACEPluginsFromDir('Slave/Client', "#{@WEACELibDir}/Install/Slave/Client", 'WEACEInstall::Slave')
      # Slave Adapters
      # Slave Products
      parseWEACEPluginsFromDir('Slave/Products', "#{@WEACELibDir}/Install/Slave/Adapters", 'WEACEInstall::Slave::Adapters')
      Dir.glob("#{@WEACELibDir}/Install/Slave/Adapters/*").each do |iProductDirName|
        if (File.directory?(iProductDirName))
          lProductID = File.basename(iProductDirName)
          # Slave Tools
          parseWEACEPluginsFromDir("Slave/Tools/#{lProductID}", "#{@WEACELibDir}/Install/Slave/Adapters/#{lProductID}", "WEACEInstall::Slave::Adapters::#{lProductID}")
          Dir.glob("#{iProductDirName}/*").each do |iToolDirName|
            if (File.directory?(iToolDirName))
              lToolID = File.basename(iToolDirName)
              # Slave Actions
              parseWEACEPluginsFromDir("Slave/Actions/#{lProductID}/#{lToolID}", "#{@WEACELibDir}/Install/Slave/Adapters/#{lProductID}/#{lToolID}", "WEACEInstall::Slave::Adapters::#{lProductID}::#{lToolID}")
            end
          end
        end
      end
      # Slave Listeners
      parseWEACEPluginsFromDir('Slave/Listeners', "#{@WEACELibDir}/Install/Slave/Listeners", 'WEACEInstall::Slave::Listeners')
    end

    # Register WEACE plugins read from a directory.
    # This reads the plugins descriptions the same parsePluginsFromDir does, but it completes the description with WEACE specific attributes.
    #
    # Parameters:
    # * *iCategoryName* (_String_): The category name of the plugins
    # * *iDir* (_String_): Directory containing plugins
    # * *iBaseClassName* (_String_): Name of the base class of every plugin in this directory
    def parseWEACEPluginsFromDir(iCategoryName, iDir, iBaseClassName)
      # Get plugins from there
      @PluginsManager.parsePluginsFromDir(iCategoryName, iDir, iBaseClassName)
      # Create the corresponding OptionsParser object, and complete the current description with it
      @PluginsManager.getPluginsDescriptions(iCategoryName).each do |iScriptID, ioDescription|
        initializePluginDescription(ioDescription)
      end
    end

    # Initialize a freshly read plugin description
    # This is used to set additional variables among the description already created by the plugins manager.
    #
    # Parameters:
    # * *ioDescription* (<em>map<Symbol,Object></em>): The description to complete
    def initializePluginDescription(ioDescription)
      if (ioDescription[:VarOptions] != nil)
        require 'optparse'
        ioDescription[:Options] = OptionParser.new
        # The map of mandatory variables, along with their description and value once affected
        # map< Symbol,       [ OptionParser, String ] >
        # map< VariableName, [ Description,  Value  ] >
        ioDescription[:MandatoryVariables] = {}
        ioDescription[:VarOptions].each do |iVarOption|
          iVariable = iVarOption[0]
          iParameters = iVarOption[1..-1]
          # Avoid duplicates
          if (ioDescription[:MandatoryVariables][iVariable] == nil)
            # Create a little OptionParser to format the parameters correctly
            lSingleOption = OptionParser.new
            lSingleOption.on(*iParameters)
            ioDescription[:MandatoryVariables][iVariable] = [ lSingleOption, nil ]
          else
            # Add this option to the variable help: 2 options can define the same variable
            ioDescription[:MandatoryVariables][iVariable][0].on(*iParameters)
          end
          # Set the variable correctly when the option is encountered
          ioDescription[:Options].on(*iParameters) do |iArg|
            ioDescription[:MandatoryVariables][iVariable][1] = iArg
          end
        end
      end
    end

    # Get the name of the file used to register an installed component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # Return:
    # * _String_: The file name
    def getInstallFileName(iComponentName)
      return "#{@WEACEInstallDir}/InstalledComponents/#{getValidFileName(iComponentName)}.inst.rb"
    end

    # Get the name of the file used to configure an installed component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # Return:
    # * _String_: The file name
    def getConfigFileName(iComponentName)
      return "#{@WEACEConfigDir}/#{getValidFileName(iComponentName)}.conf.rb"
    end

    # Get the installed description of a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # Return:
    # * <em>map<Symbol, Object></em>: The description, or nil if not installed
    def getComponentInstallInfo(iComponentName)
      return getMapFromFile(getInstallFileName(iComponentName))
    end

    # Get the installed configuration of a component
    #
    # Parameters:
    # * *iComponentName* (_String_): Component name
    # Return:
    # * <em>map<Symbol, Object></em>: The configuration, or nil if not installed
    def getComponentConfigInfo(iComponentName)
      return getMapFromFile(getConfigFileName(iComponentName))
    end

    # Get a map that was stored in a file
    #
    # Parameters:
    # * *iFileName* (_String_): Name of the file that stores the map
    # Return:
    # * <em>map<Object,Object></em>: The map read, or nil if none or no file
    def getMapFromFile(iFileName)
      rMap = nil
      
      if (File.exists?(iFileName))
        File.open(iFileName, 'r') do |iFile|
          rMap = eval(iFile.read)
        end
      end

      return rMap
    end

    # Get the list of installed Slave Products.
    # Here is the return type:
    # map< ProductName,
    #   [ ProductInstallInfo,
    #     map< ToolID,
    #       [ ToolInstallInfo,
    #         map< ActionID,
    #           [ ActionInstallInfo, Active? ]
    #         >
    #       ]
    #     >
    #   ]
    # >
    #
    # Return:
    # <em>map<String,[map<Symbol,Object>,map<String,[map<Symbol,Object>,map<String,[map<Symbol,Object>,Boolean]>]>]></em>: The list of Slave Products, along with their information
    def getInstalledSlaveProducts
      rInstalledProducts = {}

      # We will need to have SlaveClient configuration to know which installed Action is active.
      # It can be nil.
      lSlaveClientConfig = getComponentConfigInfo('SlaveClient')
      # Parse installation files and get Products only
      Dir.glob("#{@WEACEInstallDir}/InstalledComponents/*.inst.rb").each do |iProductFileName|
        lProductName = File.basename(iProductFileName)[0..-9]
        lProductInstallInfo = getComponentInstallInfo(lProductName)
        if ((lProductInstallInfo[:Product] != nil) and
            (lProductInstallInfo[:Type] == 'Slave'))
          # We have got one
          # Find its installed Tools
          #     map< ToolID,
          #       [ ToolInstallInfo,
          #         map< ActionID,
          #           [ ActionInstallInfo, Active? ]
          #         >
          #       ]
          #     >
          lInstalledTools = {}
          Dir.glob("#{@WEACEInstallDir}/InstalledComponents/#{lProductName}.*.inst.rb").each do |iToolFileName|
            lMatchData = (File.basename(iToolFileName)[0..-9]).match(/^#{lProductName}\.([^\.]*)$/)
            if (lMatchData != nil)
              # We have got one
              lToolID = lMatchData[1]
              # Find its installed Actions
              #         map< ActionID,
              #           [ ActionInstallInfo, Active? ]
              #         >
              lInstalledActions = {}
              Dir.glob("#{@WEACEInstallDir}/InstalledComponents/#{lProductName}.#{lToolID}.*.inst.rb").each do |iActionFileName|
                lActionID = (File.basename(iActionFileName)[0..-9]).match(/^#{lProductName}\.#{lToolID}\.([^\.]*)$/)[1]
                # Check if this Action is active
                lInstalledActions[lActionID] = [
                  getComponentInstallInfo("#{lProductName}.#{lToolID}.#{lActionID}"),
                  ((lSlaveClientConfig != nil) and
                   (lSlaveClientConfig[lProductName] != nil) and
                   (lSlaveClientConfig[lProductName][lToolID] != nil) and
                   (lSlaveClientConfig[lProductName][lToolID].include?(lActionID)))
                 ]
              end
              lInstalledTools[lToolID] = [ getComponentInstallInfo("#{lProductName}.#{lToolID}"), lInstalledActions ]
            end
          end
          rInstalledProducts[lProductName] = [ lProductInstallInfo, lInstalledTools ]
        end
      end

      return rInstalledProducts
    end

    # Get the list of installed Master Products.
    # Here is the return type:
    # map< ProductName,
    #   [ ProductInstallInfo,
    #     map< ProcessID, ProcessInstallInfo >
    #   ]
    # >
    #
    # Return:
    # <em>map<String,[map<Symbol,Object>,map<String,map<Symbol,Object>>]></em>: The list of Master Products, along with their information
    def getInstalledMasterProducts
      rInstalledProducts = {}

      # Parse installation files and get Products only
      Dir.glob("#{@WEACEInstallDir}/InstalledComponents/*.inst.rb").each do |iProductFileName|
        lProductName = File.basename(iProductFileName)[0..-9]
        lProductInstallInfo = getComponentInstallInfo(lProductName)
        if ((lProductInstallInfo[:Product] != nil) and
            (lProductInstallInfo[:Type] == 'Master'))
          # We have got one
          # Find its installed Processes
          #     map< ProcessID, ProcessInstallInfo >
          lInstalledProcesses = {}
          Dir.glob("#{@WEACEInstallDir}/InstalledComponents/#{lProductName}.*.inst.rb").each do |iProcessFileName|
            lProcessID = File.basename(iProcessFileName)[0..-9].match(/^#{lProductName}\.([^\.]*)$/)[1]
            lInstalledProcesses[lProcessID] = getComponentInstallInfo("#{lProductName}.#{lProcessID}")
          end
          rInstalledProducts[lProductName] = [ lProductInstallInfo, lInstalledProcesses ]
        end
      end

      return rInstalledProducts
    end

    # Setup WEACE directories in instance variables.
    # Here are the instance variables begin set:
    # * @WEACELibDir: The directory where the WEACE Toolkit library lies
    # * @WEACERepositoryDir: The directory base of the WEACE repository
    # * @WEACEInstallDir: The directory where Install related files lie
    # * @WEACEConfigDir: The directory where Configuration files lie
    # * @WEACEEnvFile: The name of the file that should contain environment setup for using WEACE Toolkit
    def setupWEACEDirs
      lWEACERepositoryDir = ENV['WEACE_CONFIG_PATH']
      @WEACELibDir = File.expand_path(File.dirname(__FILE__))

      if (lWEACERepositoryDir == nil)
        lWEACERepositoryDir = "#{File.dirname(__FILE__)}/../../config"
      end
      @WEACERepositoryDir = File.expand_path(lWEACERepositoryDir)
      @WEACEInstallDir = "#{@WEACERepositoryDir}/Install"
      @WEACEConfigDir = "#{@WEACERepositoryDir}/Config"
      @WEACEEnvFile = "#{@WEACERepositoryDir}/WEACEEnv.rb"
    end

    # Iterate through installed Adapters in the filesystem
    #
    # Parameters:
    # * *iDirectory* (_String_): The directory to parse for Adapters (Master/Slave)
    # * *iInstallDir* (_Boolean_): Do we parse the installation directory ?
    # * *CodeBlock*: The code to call for each directory found. Parameters:
    # ** *iProductID* (_String_): The product ID
    # ** *iToolID* (_String_): The tool ID
    # ** *iScriptID* (_String_): The script ID
    def eachAdapter(iDirectory, iInstallDir)
      lRootDir = File.dirname(__FILE__)
      lScriptPrefix = ''
      if (iInstallDir)
        lRootDir += '/Install'
        lScriptPrefix = 'Install_'
      end
      Dir.glob("#{lRootDir}/#{iDirectory}/Adapters/*") do |iFileName1|
        if (File.directory?(iFileName1))
          lProductID = File.basename(iFileName1)
          Dir.glob("#{lRootDir}/#{iDirectory}/Adapters/#{lProductID}/*") do |iFileName2|
            if (File.directory?(iFileName2))
              lToolID = File.basename(iFileName2)
              Dir.glob("#{lRootDir}/#{iDirectory}/Adapters/#{lProductID}/#{lToolID}/#{lScriptPrefix}*.rb") do |iFileName3|
                if (!File.directory?(iFileName3))
                  lScriptID = File.basename(iFileName3).match(/#{lScriptPrefix}(.*)\.rb/)[1]
                  yield(lProductID, lToolID, lScriptID)
                end
              end
            end
          end
        end
      end
    end

    # Check that an instance variable has been correctly instantiated, and give a good looking exception otherwise.
    #
    # Parameters:
    # * *iVariable* (_Symbol_): The variable we are looking for.
    # * *iDescription* (_String_): The description of this variable. This will appear in the eventual error message.
    def checkVar(iVariable, iDescription)
      if (!self.instance_variables.include?("@#{iVariable}"))
        logErr "Variable #{iVariable} (#{iDescription}) not set. Check your configuration."
        raise MissingVariableError, "Variable #{iVariable} (#{iDescription}) not set. Check your configuration."
      end
    end

    # Store a map of variable names and their corresponding values as instance variables of a given class
    #
    # Parameters:
    # * *ioObject* (_Object_): Object where we want to instantiate those variables
    # * *iVars* (<em>map<Symbol,Object></em>): The map of variables and their values
    def instantiateVars(ioObject, iVars)
      iVars.each do |iVariable, iValue|
        ioObject.instance_variable_set("@#{iVariable}".to_sym, iValue)
      end
    end
  
    # Split parameters, before and after the first -- encountered
    #
    # Parameters:
    # * *iParameters* (<em>list<String></em>): The parameters
    # Return:
    # * <em>list<String></em>: The first part
    # * <em>list<String></em>: The second part
    def splitParameters(iParameters)
      rFirstPart = iParameters
      rSecondPart = []

      lIdxSeparator = iParameters.index('--')
      if (lIdxSeparator != nil)
        if (lIdxSeparator == 0)
          rFirstPart = []
        else
          rFirstPart = iParameters[0..lIdxSeparator-1]
        end
        if (lIdxSeparator == iParameters.size-1)
          rSecondPart = []
        else
          rSecondPart = iParameters[lIdxSeparator+1..-1]
        end
      end

      return rFirstPart, rSecondPart
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

    # Start a MySQL transaction, connecting first to the database.
    #
    # Parameters:
    # * *iMySQLHost* (_String_): The name of the MySQL host
    # * *iDBName* (_String_): The name of the database of Redmine
    # * *iDBUser* (_String_): The name of the database user
    # * *iDBPassword* (_String_): The password of the database user
    # * _CodeBlock_: The code called once the Transaction is created
    # ** *ioSQL* (_Object_): The SQL object used to perform queries
    def beginMySQLTransaction(iMySQLHost, iDBName, iDBUser, iDBPassword)
      # Go on with real MySQL library
      require 'rubygems'
      require 'mysql'
      # Connect to the db
      lMySQL = Mysql::new(iMySQLHost, iDBUser, iDBPassword, iDBName)
      # Create a transaction
      lMySQL.query("start transaction")
      begin
        yield(lMySQL)
        lMySQL.query("commit")
      rescue RuntimeError
        lMySQL.query("rollback")
        raise
      end
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
      beginMySQLTransaction(iMySQLHost, iDBName, iDBUser, iDBPassword) do |ioSQL|
        executeSQL(ioSQL, *iParameters)
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
      lInfo.LogFile = getLogFile
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
      execCmd("#{iShellCmd}; ruby -w Execute.rb #{lFileName} 2>&1")
    end
  
    # Execute a command
    #
    # Parameters:
    # * *iCmd* (_String_): The command to execute
    def execCmd(iCmd)
      lOutput = `#{iCmd}`
      lErrorCode = $?
      if (lErrorCode != 0)
        logErr "Error while running command \"#{iCmd}\". Here is the output:\n#{lOutput}."
        raise RuntimeError, "Error while running command \"#{iCmd}\". Here is the output:\n#{lOutput}."
      end
    end
    
    # Modify a file in a safe way (exception protected, keep copy of original...).
    # It inserts (just before the end marker) or replaces some of the content of this file, between 2 markers (1 begin and 1 end markers).
    #
    # Parameters:
    # * *iFileName* (_String_): The file to modify
    # * *iBeginMarker* (_RegExp_): The begin marker (can be nil if it represents the beginning of the file)
    # * *iNewLines* (_String_): The text to insert between the markers
    # * *iEndMarker* (_RegExp_): The end marker (can be nil if it represents the end of the file)
    # * *iOptions* (_Hash_): Additional parameters: [ optional = {} ]
    # ** *:Replace* (_Boolean_): Do we completely replace the text between the markers ? [optional = false]
    # ** *:NoBackup* (_Boolean_): Do we skip backuping the file ? [optional = false]
    # ** *:CheckMatch* (<em>list<Object></em>): List of String or RegExp used to check if the new content is already present. If not specified, an exact match on iNewLines is performed. [optional = nil]
    # ** *:ExtraLinesDuringMatch* (_Boolean_): Do we ignore extra lines that could be present between the lines to match ? [optional = false]
    # ** *:CommitModifications* (_Boolean_): Do we actually commit modifications made ? [optional = true]
    # Return:
    # * _Exception_: An error, or nil in case of success
    def modifyFile(iFileName, iBeginMarker, iNewLines, iEndMarker, iOptions = {})
      rError = nil

      # Parse options
      lReplace = iOptions[:Replace]
      if (lReplace == nil)
        lReplace = false
      end
      lNoBackup = iOptions[:NoBackup]
      if (lNoBackup == nil)
        lNoBackup = false
      end
      lCheckMatch = iOptions[:CheckMatch]
      lExtraLinesDuringMatch = iOptions[:ExtraLinesDuringMatch]
      if (lExtraLinesDuringMatch == nil)
        lExtraLinesDuringMatch = false
      end
      lCommitModifications = iOptions[:CommitModifications]
      if (lCommitModifications == nil)
        lCommitModifications = true
      end

      # First check file's existence
      if (!File.exists?(iFileName))
        rError = MissingFileError.new("File #{iFileName} is missing.")
      else
        logDebug "Modify file #{iFileName} ..."
        if ((!lNoBackup) and
            lCommitModifications)
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
          rError = FileModificationError.new("Unable to find beginning mark /#{iBeginMarker}/ in file #{iFileName}. Aborting modification.")
        elsif (lIdxEnd == nil)
          rError = FileModificationError.new("Unable to find ending mark /#{iEndMarker}/ in file #{iFileName}. Aborting modification.")
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
          if (lCheckMatch != nil)
            lMatchLines = lCheckMatch
          end
          lFound = false
          if (lIdxBegin < lIdxEnd-lMatchLines.size)
            if (lExtraLinesDuringMatch)
              # Compare the lines one after the other, ignoring the ones that don't match.
              # It is just required that every match is matched in its order.
              lIdxNextLineToMatch = 0
              (lIdxBegin+1 .. lIdxEnd-lMatchLines.size).each do |iIdx|
                if (((lMatchLines[lIdxNextLineToMatch].is_a?(String)) and
                     (lContent[iIdx] == lMatchLines[lIdxNextLineToMatch])) or
                    ((lMatchLines[lIdxNextLineToMatch].is_a?(Regexp)) and
                     (lContent[iIdx].match(lMatchLines[lIdxNextLineToMatch]) != nil)))
                  # It matches
                  lIdxNextLineToMatch += 1
                  if (lIdxNextLineToMatch == lMatchLines.size)
                    # They have all matched
                    lFound = true
                    break
                  end
                end
              end
            else
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
          end
          if (lFound)
            # Already here
            if (lCommitModifications)
              logWarn "File #{iFileName} already contains modifications. It will be left unchanged."
            end
          elsif (lCommitModifications)
            # Modify the content in memory
            if (lReplace == true)
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
              logErr "Exception while writing file #{iFileName}: #{$!}. The file content has been reverted back to original."
              raise RuntimeError, "Exception while writing file #{iFileName}: #{$!}. The file content has been reverted back to original."
            end
            logDebug "File #{iFileName} modified successfully."
          end
        end
      end

      return rError
    end
    
  end

end
