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
        # Return:
        # * _Exception_: The error returned by the installer
        def executeInstall(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
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

          # Create the installer
          lInstaller = WEACEInstall::Installer.new

          # Mute any output except for terminal output.
          setLogErrorsStack([])
          setLogMessagesStack([])

          # Clear variables set in tests
          $Variables = {}

          # Create a new repository by copying the wanted one
          lSourceRepositoryDir = File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}")
          @RepositoryDir = "#{Dir.tmpdir}/WEACETestRepository"
          copyDir(lSourceRepositoryDir, @RepositoryDir)
          # Change the installer repository location internally
          lInstaller.instance_variable_set(:@WEACEInstallDir, "#{@RepositoryDir}/Install")
          lInstaller.instance_variable_set(:@WEACEConfigDir, "#{@RepositoryDir}/Config")
          lInstaller.instance_variable_set(:@WEACEInstalledComponentsDir, "#{@RepositoryDir}/Install/InstalledComponents")

          # Ensure that the directory will be cleaned whatever happens
          begin

            # Add additional components for the regression here
            if (lAddRegressionMasterAdapters or
                lAddRegressionSlaveAdapters or
                lAddRegressionSlaveListeners or
                lAddRegressionMasterProviders or
                lAddRegressionSlaveProviders)
              # Change the library directory (save it to restore it after)
              lNewWEACELibDir = File.expand_path("#{File.dirname(__FILE__)}/../Components")
              lOldWEACELibDir = lInstaller.instance_variable_get(:@WEACELibDir)
              lInstaller.instance_variable_set(:@WEACELibDir, lNewWEACELibDir)

              if (lAddRegressionMasterAdapters)
                # Get the current adapters
                lCurrentAdapters = lInstaller.instance_variable_get(:@MasterAdapters)
                # Parse for the regression adapters
                lInstaller.send(:parseAdapters, 'Master', lCurrentAdapters)
                # Change the adapters with the newly parsed ones
                lInstaller.instance_variable_set(:@MasterAdapters, lCurrentAdapters)
              end

              if (lAddRegressionSlaveAdapters)
                # Get the current adapters
                lCurrentAdapters = lInstaller.instance_variable_get(:@SlaveAdapters)
                # Parse for the regression adapters
                lInstaller.send(:parseAdapters, 'Slave', lCurrentAdapters)
                # Change the adapters with the newly parsed ones
                lInstaller.instance_variable_set(:@SlaveAdapters, lCurrentAdapters)
              end

              if (lAddRegressionSlaveListeners)
                lInstaller.send(:parseWEACEPluginsFromDir, 'Slave/Listeners', "#{lNewWEACELibDir}/Install/Slave/Listeners", 'WEACEInstall::Slave::Listeners')
              end

              if (lAddRegressionMasterProviders)
                lInstaller.send(:parseWEACEPluginsFromDir, 'Master/Providers', "#{lNewWEACELibDir}/Install/Master/Providers", 'WEACEInstall::Master::Providers', false)
              end

              if (lAddRegressionSlaveProviders)
                lInstaller.send(:parseWEACEPluginsFromDir, 'Slave/Providers', "#{lNewWEACELibDir}/Install/Slave/Providers", 'WEACEInstall::Slave::Providers', false)
              end

              # Restore back the WEACE lib dir
              lInstaller.instance_variable_set(:@WEACELibDir, lOldWEACELibDir)
            end

            # Install effectively
            lError = lInstaller.execute(iParameters)
            #lError = lInstaller.execute(['-d']+iParameters)
            #p lError
            if (lExpectedErrorClass == nil)
              assert_equal(nil, lError)
            else
              assert(lError.kind_of?(lExpectedErrorClass))
            end

            # Call additional checks from the test case itself
            if (iCheckCode != nil)
              iCheckCode.call(lError)
            end

          ensure
            # Clean the mess of this test
            FileUtils::rm_rf(@RepositoryDir)
          end
        end

      end

    end

  end

end
