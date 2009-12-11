#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'
require 'bin/WEACEInstall'

module WEACE

  module Test

    module Install

      module Common

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

        # Initialize the installer
        #
        # Parameters:
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        # ** *:AddRegressionMasterAdapters (_Boolean_): Do we add the Master Adapters from regression ? [optional = false]
        # ** *:AddRegressionSlaveAdapters (_Boolean_): Do we add the Slave Adapters from regression ? [optional = false]
        # ** *:AddRegressionSlaveListeners (_Boolean_): Do we add the Slave Listeners from regression ? [optional = false]
        # ** *:AddRegressionMasterProviders (_Boolean_): Do we add the Master Providers from regression ? [optional = false]
        # ** *:AddRegressionSlaveProviders (_Boolean_): Do we add the Slave Providers from regression ? [optional = false]
        # * _CodeBlock_: The code called once the installer was created
        def initInstaller(iOptions = {})
          # Parse options
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Empty'
          end
          lAddRegressionMasterAdapters = iOptions[:AddRegressionMasterAdapters]
          if (lAddRegressionMasterAdapters == nil)
            lAddRegressionMasterAdapters = false
          end
          lAddRegressionSlaveAdapters = iOptions[:AddRegressionSlaveAdapters]
          if (lAddRegressionSlaveAdapters == nil)
            lAddRegressionSlaveAdapters = false
          end
          lAddRegressionSlaveListeners = iOptions[:AddRegressionSlaveListeners]
          if (lAddRegressionSlaveListeners == nil)
            lAddRegressionSlaveListeners = false
          end
          lAddRegressionMasterProviders = iOptions[:AddRegressionMasterProviders]
          if (lAddRegressionMasterProviders == nil)
            lAddRegressionMasterProviders = false
          end
          lAddRegressionSlaveProviders = iOptions[:AddRegressionSlaveProviders]
          if (lAddRegressionSlaveProviders == nil)
            lAddRegressionSlaveProviders = false
          end

          # The possible variables replaced in regression test files (command lines, repositories...)
          #   map< Symbol, Object >
          @ContextVars = {}

          # Mute any output except for terminal output.
          setLogErrorsStack([])
          setLogMessagesStack([])

          # Clear variables set in tests
          $Variables = {}

          # Create the installer
          @Installer = WEACEInstall::Installer.new

          # Create a new WEACE repository by copying the wanted one
          lSourceRepositoryDir = File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}")
          setupTmpDir(lSourceRepositoryDir, 'WEACETestRepository') do |iTmpDir|
            @WEACERepositoryDir = iTmpDir

            # Change the installer repository location internally
            @Installer.instance_variable_set(:@WEACEInstallDir, "#{@WEACERepositoryDir}/Install")
            @Installer.instance_variable_set(:@WEACEConfigDir, "#{@WEACERepositoryDir}/Config")
            @Installer.instance_variable_set(:@WEACEInstalledComponentsDir, "#{@WEACERepositoryDir}/Install/InstalledComponents")

            # Add additional components for the regression here
            if (lAddRegressionMasterAdapters or
                lAddRegressionSlaveAdapters or
                lAddRegressionSlaveListeners or
                lAddRegressionMasterProviders or
                lAddRegressionSlaveProviders)
              # Change the library directory (save it to restore it after)
              lNewWEACELibDir = File.expand_path("#{File.dirname(__FILE__)}/../Components")
              lOldWEACELibDir = @Installer.instance_variable_get(:@WEACELibDir)
              @Installer.instance_variable_set(:@WEACELibDir, lNewWEACELibDir)

              if (lAddRegressionMasterAdapters)
                # Get the current adapters
                lCurrentAdapters = @Installer.instance_variable_get(:@MasterAdapters)
                # Parse for the regression adapters
                @Installer.send(:parseAdapters, 'Master', lCurrentAdapters)
                # Change the adapters with the newly parsed ones
                @Installer.instance_variable_set(:@MasterAdapters, lCurrentAdapters)
              end

              if (lAddRegressionSlaveAdapters)
                # Get the current adapters
                lCurrentAdapters = @Installer.instance_variable_get(:@SlaveAdapters)
                # Parse for the regression adapters
                @Installer.send(:parseAdapters, 'Slave', lCurrentAdapters)
                # Change the adapters with the newly parsed ones
                @Installer.instance_variable_set(:@SlaveAdapters, lCurrentAdapters)
              end

              if (lAddRegressionSlaveListeners)
                @Installer.send(:parseWEACEPluginsFromDir, 'Slave/Listeners', "#{lNewWEACELibDir}/Install/Slave/Listeners", 'WEACEInstall::Slave::Listeners')
              end

              if (lAddRegressionMasterProviders or
                  lAddRegressionMasterAdapters)
                @Installer.send(:parseWEACEPluginsFromDir, 'Master/Providers', "#{lNewWEACELibDir}/Install/Master/Providers", 'WEACEInstall::Master::Providers', false)
              end

              if (lAddRegressionSlaveProviders or
                  lAddRegressionSlaveAdapters or
                  lAddRegressionSlaveListeners)
                @Installer.send(:parseWEACEPluginsFromDir, 'Slave/Providers', "#{lNewWEACELibDir}/Install/Slave/Providers", 'WEACEInstall::Slave::Providers', false)
              end

              # Restore back the WEACE lib dir
              @Installer.instance_variable_set(:@WEACELibDir, lOldWEACELibDir)
            end

            # Set the ContextVars that can be needed from the Provider Environments
            lMinorError, lMasterConf = @Installer.getAlreadyCreatedProviderConfig('Master')
            if (lMasterConf != nil)
              if (lMasterConf[:WEACEMasterInfoURL] != nil)
                @ContextVars['WEACEMasterInfoURL'] = lMasterConf[:WEACEMasterInfoURL]
              end
            end
            lMinorError, lSlaveConf = @Installer.getAlreadyCreatedProviderConfig('Slave')
            if (lSlaveConf != nil)
              if (lSlaveConf[:WEACESlaveInfoURL] != nil)
                @ContextVars['WEACESlaveInfoURL'] = lSlaveConf[:WEACESlaveInfoURL]
              end
            end

            # Call client code
            yield

            # Clean installer
            @Installer = nil

          end
        end

        # Execute the installer and check its output.
        # Prerequisite: call initInstaller before.
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give the installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        # Return:
        # * _Exception_: Error returned by the Installer's execution
        def execInstaller(iParameters, iOptions)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]

          # Execute
          rError = @Installer.execute(iParameters)
          #rError = @Installer.execute(['-d']+iParameters)
          #p rError

          # Check
          if (lExpectedErrorClass == nil)
            assert_equal(nil, rError)
          else
            assert(rError.kind_of?(lExpectedErrorClass))
          end

          return rError
        end

        # Execute the WEACEInstall script with some given parameters, and check its error.
        #
        # Parmeters:
        # * *iParameters* (<em>list<String></em>): The parameters to give the installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        # ** *:AddRegressionMasterAdapters (_Boolean_): Do we add the Master Adapters from regression ? [optional = false]
        # ** *:AddRegressionSlaveAdapters (_Boolean_): Do we add the Slave Adapters from regression ? [optional = false]
        # ** *:AddRegressionSlaveListeners (_Boolean_): Do we add the Slave Listeners from regression ? [optional = false]
        # ** *:AddRegressionMasterProviders (_Boolean_): Do we add the Master Providers from regression ? [optional = false]
        # ** *:AddRegressionSlaveProviders (_Boolean_): Do we add the Slave Providers from regression ? [optional = false]
        # * _CodeBlock_: The code called once the installer was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the installer, or nil in case of success
        def executeInstall(iParameters, iOptions = {}, &iCheckCode)
          # Initialize
          initInstaller(iOptions) do
            # Execute
            lError = execInstaller(iParameters, iOptions)
            # Call additional checks from the test case itself
            if (iCheckCode != nil)
              iCheckCode.call(lError)
            end
          end

        end

      end

    end

  end

end
