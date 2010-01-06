#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'
require 'bin/WEACEInstall'

module WEACE

  # Needed to change the way the WEACE Slave Client behaves
  module Slave

    class Client

      # Prepare the next WEACE Slave Clients to be executed to alter their own behaviour.
      # Their behaviour will be altered just before their execution:
      # * It will change their WEACE Repository path
      # * It will eventually add the Regression Slave Adapters plugin
      # * It will eventually install some Actions
      # * It will eventually configure some Products
      #
      # Parameters:
      # * *iNewWEACERepositoryDir* (_String_): New repository path to be used
      # * *iAddRegressionActions* (_Boolean_): Do we add regression Actions ?
      # * *iInstallActions* (<em>list<[String,String,String]></em>): List of Actions to install: [ ProductID, ToolID, ActionID ].
      # * *iConfigureProducts* (<em>list<[String,String,map<Symbol,Object>]></em>): The list of Product/Tool to configure: [ ProductID, ToolID, Parameters ].
      # * *CodeBlock*: The code to execute once the class has been prepared
      def self.changeClient(iNewWEACERepositoryDir, iAddRegressionActions, iInstallActions, iConfigureProducts)
        @@Regression_WEACERepositoryDir, @@Regression_AddRegressionActions, @@Regression_InstallActions, @@Regression_ConfigureProducts = iNewWEACERepositoryDir, iAddRegressionActions, iInstallActions, iConfigureProducts
        WEACE::Test::Common::changeMethod(
          WEACE::Slave::Client,
          :execute,
          :execute_Regression,
          true
        ) do
          yield
        end
        # Clean up
        @@Regression_WEACERepositoryDir = nil
        @@Regression_AddRegressionActions = nil
        @@Regression_InstallActions = nil
        @@Regression_ConfigureProducts = nil
      end

      # Execute the server for a given configuration
      #
      # Parameters:
      # * *iParameters* (<em>list<String></em>): The parameters
      # Return:
      # * _Exception_: An error, or nil in case of success
      def execute_Regression(iParameters)
        # First, we parse, install and configure Actions from the Regression
        # Change the repository location internally in WEACE Slave Client
        changeRepositoryPath(@@Regression_WEACERepositoryDir)
        # Add regression Components if needed
        if (@@Regression_AddRegressionActions)
          addRegressionActions
        end
        # Register actions if needed
        if (@@Regression_InstallActions != nil)
          installActions(@@Regression_InstallActions)
        end
        # Configure Products if needed
        if (@@Regression_ConfigureProducts != nil)
          configureProducts(@@Regression_ConfigureProducts)
        end

        return execute_Original(iParameters)
      end

      # Change the repository location
      #
      # Parameters:
      # * *iRepositoryPath* (_String_): New repository location
      def changeRepositoryPath(iRepositoryPath)
        @WEACEInstallDir = "#{iRepositoryPath}/Install"
        @DefaultLogDir = "#{iRepositoryPath}/Log"
        @ConfigFile = "#{iRepositoryPath}/Config/SlaveClient.conf.rb"
      end

      # Add Regression Actions
      def addRegressionActions
        lNewWEACELibDir = File.expand_path("#{File.dirname(__FILE__)}/Components")
        parseAdapters("#{lNewWEACELibDir}/Slave/Adapters")
      end

      # Mark some Actions as being installed
      #
      # Parameters:
      # * *iInstallActions* (<em>list<[String,String,String]></em>): List of Actions to install: [ ProductID, ToolID, ActionID ].
      def installActions(iInstallActions)
        iInstallActions.each do |iInstalledActionInfo|
          iProductID, iToolID, iActionID = iInstalledActionInfo
          # Register the Action among the installed ones
          if (@Actions[iToolID] == nil)
            @Actions[iToolID] = {}
          end
          if (@Actions[iToolID][iActionID] == nil)
            @Actions[iToolID][iActionID] = [ [], [] ]
          end
          lFound = false
          @Actions[iToolID][iActionID][0].each do |ioProductInfo|
            iKnownProductID, iInstalled = ioProductInfo
            if (iKnownProductID == iProductID)
              ioProductInfo[1] = true
              lFound = true
            end
            if (lFound)
              break
            end
          end
          if (!lFound)
            # Add it
            @Actions[iToolID][iActionID][0] << [ iProductID, true ]
          end
        end
      end

      # Add some Products to the configuration
      #
      # Parameters:
      # * *iConfigureProducts* (<em>list<[String,String,map<Symbol,Object>]></em>): The list of Product/Tool to configure: [ ProductID, ToolID, Parameters ].
      def configureProducts(iConfigureProducts)
        # Bypass the configuration file reader to force our configuration
        lError, $WEACESlaveConfig = readConfigFile
        def self.readConfigFile
          return nil, $WEACESlaveConfig
        end
        iConfigureProducts.each do |iProductInfo|
          iProductID, iToolID, iProductConfig = iProductInfo
          $WEACESlaveConfig[:WEACESlaveAdapters] << iProductConfig.merge(
            {
              :Product => iProductID,
              :Tool => iToolID
            }
          )
        end
      end

    end

  end

  module Test

    module Common

      # Change a method into another of a specific class, and ensure changing it back.
      #
      # Parameters:
      # * *iClass* (_class_): Class in which we change the method
      # * *iOldMethod* (_Symbol_): Symbol of the method to replace
      # * *iNewMethod* (_Symbol_): Symbol of the replacing method
      # * *iActive* (_Boolean_): Do we actually perform the change ? If not, nothing is done except calling the code block.
      # * *CodeBlock*: Code called once the method has been changed
      def self.changeMethod(iClass, iOldMethod, iNewMethod, iActive)
        if (iActive)
          iClass.module_eval("
            alias :#{iOldMethod}_Original :#{iOldMethod}
            alias :#{iOldMethod} :#{iNewMethod}
            ")
          begin
            yield
          rescue Exception
            iClass.module_eval("
              alias :#{iNewMethod} :#{iOldMethod}
              alias :#{iOldMethod} :#{iOldMethod}_Original
              ")
            raise
          end
          iClass.module_eval("
            alias :#{iNewMethod} :#{iOldMethod}
            alias :#{iOldMethod} :#{iOldMethod}_Original
            ")
        else
          yield
        end
      end

      # Get details about the test case currently running (based on the class name)
      #
      # Return:
      # * _String_: The type (Master|Slave)
      # * _String_: The Product ID
      # * _String_: The Tool ID
      # * _String_: The Script ID
      # * _String_: The test case name
      # * _Boolean_: Does this test case test installation scripts ?
      def getTestDetails
        rType = nil
        rProductID = nil
        rToolID = nil
        rScriptID = nil
        rTestName = 'unknown'
        rInstallTest = nil

        # Get the ID of the test, based on its class name
        lMatchData = self.class.name.match(/^WEACE::Test::Install::(.*)::Adapters::(.*)::(.*)::(.*)$/)
        if (lMatchData == nil)
          lMatchData = self.class.name.match(/^WEACE::Test::(.*)::Adapters::(.*)::(.*)::(.*)$/)
          if (lMatchData == nil)
            logErr "Testing class (#{self.class.name}) is not of the form WEACE::Test[::Install]::{Master|Slave}::Adapters::<ProductID>::<ToolID>::<ScriptID>"
            raise RuntimeError, "Testing class (#{self.class.name}) is not of the form WEACE::Test[::Install]::{Master|Slave}::Adapters::<ProductID>::<ToolID>::<ScriptID>"
          else
            rType, rProductID, rToolID, rScriptID = lMatchData[1..4]
            rInstallTest = false
          end
        else
          rType, rProductID, rToolID, rScriptID = lMatchData[1..4]
          rInstallTest = true
        end
        # Remove the beginning 'test' from the method name
        rTestName = @method_name[4..-1]

        return rType, rProductID, rToolID, rScriptID, rTestName, rInstallTest
      end

      # Initialization of every test case.
      # This method can then be used in setup or in single execution methods.
      # It ensures that logging mechanism will be correctly initialized and finalized
      #
      # Parameters:
      # * _CodeBlock_: Code executed once the test case has been initialized
      def initTestCase
        # The possible variables replaced in regression test files (command lines, repositories...)
        #   map< Symbol, Object >
        @ContextVars = {}
        # Mute any output except for terminal output.
        setLogErrorsStack([])
        setLogMessagesStack([])
        # Clear variables set in tests
        $Variables = {}

        begin
          yield
        rescue Exception
          setLogFile(nil)
          raise
        end
        setLogFile(nil)
      end

      # Replace variables that can be used in lines of test files.
      # Use @ContextVars to decide which variables to replace.
      # Replace alse '%%' with '%'
      # Don't replace anything if @ContextVars is not defined.
      #
      # Parameters:
      # * *iLine* (_String_): The line containing variables
      # Return:
      # * _String_: The line with variables replaced
      def replaceVars(iLine)
        rResult = iLine.clone

        if (defined?(@ContextVars))
          @ContextVars.each do |iVariable, iValue|
            rResult.gsub!("%{#{iVariable}}", iValue)
          end
          rResult.gsub!('%%', '%')
        end

        return rResult
      end

      # Copy a directory content into another, ignoring SVN files
      #
      # Parameters:
      # * *iSrcDir* (_String_): Source directory
      # * *iDstDir* (_String_): Destination directory
      def copyDir(iSrcDir, iDstDir)
        FileUtils.mkdir_p(iDstDir)
        Dir.glob("#{iSrcDir}/*").each do |iFileName|
          lBaseName = File.basename(iFileName)
          if (File.directory?(iFileName))
            # Ignore .svn directory
            if (lBaseName != '.svn')
              copyDir(iFileName, "#{iDstDir}/#{lBaseName}")
            end
          else
            # Copy a file, eventually replacing variables in it
            lContent = nil
            File.open(iFileName, 'r') do |iFile|
              lContent = iFile.readlines
            end
            File.open("#{iDstDir}/#{lBaseName}", 'w') do |iFile|
              lContent.each do |iLine|
                iFile << replaceVars(iLine)
              end
            end
          end
        end
      end

      # Create a temporary directory as a copy of another directory, and ensure it will be deleted after some code has been executed.
      # The temporary directory is not the exact image of the source one: files can be altered by using @ContextVars.
      #
      # Parameters:
      # * *iSrcDir* (_String_): Source directory to copy from
      # * *iBaseName* (_String_): Name to be used in the temporary directory [optional = nil]
      # * _CodeBlock_: The code called once the temporary has been created:
      # ** *iTmpDir* (_String_): Name of the temporary directory, image of the source one.
      def setupTmpDir(iSrcDir, iBaseName = nil)
        # Find a good temporary directory name
        lTmpDir = nil
        if (!defined?(@@UniqueCounter))
          @@UniqueCounter = 0
        end
        if (iBaseName == nil)
          lTmpDir = "#{Dir.tmpdir}/WEACERegression/Dir_#{@@UniqueCounter}"
        else
          lTmpDir = "#{Dir.tmpdir}/WEACERegression/#{iBaseName}_#{@@UniqueCounter}"
        end
        @@UniqueCounter += 1
        # Copy the directories
        logDebug "-> Create image of #{iSrcDir} in #{lTmpDir}"
        # Clean first if already present
        if (File.exists?(lTmpDir))
          FileUtils::rm_rf(lTmpDir)
        end
        copyDir(iSrcDir, lTmpDir)
        # Call the code (protected)
        begin
          yield(lTmpDir)
        ensure
          # Delete the temporary directory
          FileUtils::rm_rf(lTmpDir)
        end
      end

    end

  end

end
