#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'
require 'bin/WEACEInstall'

module WEACE

  module Test

    module Install

      module Common

        include WEACE::Common
        include WEACE::Test::Common

        # Setup a Product temporary repository as an image of a given repository.
        # The repository is then deleted once the code block finishes.
        #
        # Parameters::
        # * *iRepositoryName* (_String_): Name of the repository to use as an image.
        # * *CodeBlock*: Code called once the repository is created.
        def setupRepository(iRepositoryName)
          if ((defined?(@ProductRepositoryDir)) and
              (@ProductRepositoryDir != nil))
            log_err "A repository has already been setup in this test case: #{@ProductRepositoryDir}. You can not cascade repository setups."
            raise RuntimeError, "A repository has already been setup in this test case: #{@ProductRepositoryDir}. You can not cascade repository setups."
          end
          setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../ProductRepositories/#{iRepositoryName}"), @ProductID) do |iTmpDir|
            @ProductRepositoryDir = iTmpDir
            @ContextVars['ProductDir'] = @ProductRepositoryDir
            yield
            @ProductRepositoryDir = nil
          end
        end

        # Compare the current Product repository with a reference repository
        #
        # Parameters::
        # * *iRepositoryName* (_String_): Name of the repository to use as a reference.
        def compareWithRepository(iRepositoryName)
          if ((!defined?(@ProductRepositoryDir)) or
              (@ProductRepositoryDir == nil))
            log_err "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
            raise RuntimeError, "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
          end
          log_debug "Compare repositories with reference #{iRepositoryName}"
          assert_equal(true, compareDirs(@ProductRepositoryDir, File.expand_path("#{File.dirname(__FILE__)}/../ProductRepositories/#{iRepositoryName}")))
        end

        # Compare 2 files contents.
        # This is used for testing purposes. It compares each file (replacing variables and matching regexps if needed).
        # The second file is considered the reference, and is the only one who can contain regexps.
        # Regexps are identified like this, from the beginning of the line:
        # %/<RegExp>/
        #
        # Parameters::
        # * *iFile1* (_String_): First directory
        # * *iFile2* (_String_): Second directory
        # * *iVarContext* (<em>map<String,String></em>): The variables to be replaced
        # Return::
        # * _Boolean_: Are files the same ?
        def compareFiles(iFile1, iFile2)
          rResult = false

          lContent1 = nil
          File.open(iFile1, 'r') do |iFile|
            lContent1 = iFile.readlines
          end
          lContent2 = nil
          File.open(iFile2, 'r') do |iFile|
            lContent2 = iFile.readlines
          end
          if (lContent1.size == lContent2.size)
            rResult = true
            (0..lContent1.size-1).each do |iIdx|
              # Replace variables in lContent1 and lContent2
              lReference = replaceVars(lContent2[iIdx])
              # Look for a regexp
              if (lContent2[iIdx][0..1] == '%/')
                # Remove the %/ .. / characters
                lReference = lReference[2..-2]
                # Regexp
                if (lContent1[iIdx].match(lReference) == nil)
                  # A difference
                  log_err "Files #{iFile1} and #{iFile2} differ on line #{iIdx}: '#{lContent1[iIdx]}' should match /#{lReference}/."
                  rResult = false
                  break
                end
                # String comparison
              elsif (lContent1[iIdx] != lReference)
                # A difference
                log_err "Files #{iFile1} and #{iFile2} differ on line #{iIdx}:\n'#{lContent1[iIdx]}'\nshould be\n'#{lReference}'."
                rResult = false
                break
              end
            end
          else
            log_err "Number of lines differ from #{iFile1} (#{lContent1.size} lines), and #{iFile2} (#{lContent2.size} lines)."
          end

          return rResult
        end

        # Compare 2 directories contents.
        # This is used for testing purposes. It compares each file (replacing variables and matching regexps if needed).
        # The second directory is taken as the reference.
        # Files whose extension is .WEACEBackup from the first directories are ignored.
        # Parameters::
        # * *iDir1* (_String_): First directory
        # * *iDir2* (_String_): Second directory
        # Return::
        # * _Boolean_: Are directories the same ?
        def compareDirs(iDir1, iDir2)
          rResult = false

          # First, the contents
          lDir1Content = []
          Dir.glob("#{iDir1}/*").each do |iFileName|
            if (iFileName[-12..-1] != '.WEACEBackup')
              lDir1Content << File.basename(iFileName)
            end
          end
          lDir2Content = []
          Dir.glob("#{iDir2}/*").each do |iFileName|
            lDir2Content << File.basename(iFileName)
          end
          if (lDir1Content.size == lDir2Content.size)
            # Get the list of files and directories
            rResult = true
            lFiles = []
            lDirs = []
            lDir2Content.each do |iFileName|
              if (lDir1Content.index(iFileName) == nil)
                # A difference
                log_err "File #{iFileName} exists in #{iDir2}, but not in #{iDir1}."
                rResult = false
                break
              end
            end
            lDir1Content.each do |iFileName|
              if (lDir2Content.index(iFileName) == nil)
                # A difference
                log_err "File #{iFileName} exists in #{iDir1}, but not in #{iDir2}."
                rResult = false
                break
              end
              if (File.directory?("#{iDir1}/#{iFileName}"))
                if (File.directory?("#{iDir2}/#{iFileName}"))
                  lDirs << iFileName
                else
                  # A difference
                  log_err "Directory #{iFileName} from #{iDir1} is a file in #{iDir2}."
                  rResult = false
                  break
                end
              elsif (!File.directory?("#{iDir2}/#{iFileName}"))
                lFiles << iFileName
              else
                # A difference
                log_err "File #{iFileName} from #{iDir1} is a directory in #{iDir2}."
                rResult = false
                break
              end
            end
            if (rResult)
              # Now we compare each directory
              lDirs.each do |iDir|
                rResult = compareDirs("#{iDir1}/#{iDir}", "#{iDir2}/#{iDir}")
                if (!rResult)
                  break
                end
              end
              if (rResult)
                # Now we compare each file
                lFiles.each do |iFile|
                  rResult = compareFiles("#{iDir1}/#{iFile}", "#{iDir2}/#{iFile}")
                  if (!rResult)
                    break
                  end
                end
              end
            end
          else
            log_err "Number of files differ from #{iDir1} (#{lDir1Content.size} files), and #{iDir2} (#{lDir2Content.size} files)."
          end

          return rResult
        end

        # Initialize the installer
        #
        # Parameters::
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        #   * *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        #   * *:ProductRepository* (_String_): Name of the Product repository to use [optional = 'Empty']
        #   * *:AddRegressionMasterAdapters (_Boolean_): Do we add the Master Adapters from regression ? [optional = false]
        #   * *:AddRegressionSlaveAdapters (_Boolean_): Do we add the Slave Adapters from regression ? [optional = false]
        #   * *:AddRegressionSlaveListeners (_Boolean_): Do we add the Slave Listeners from regression ? [optional = false]
        #   * *:AddRegressionMasterProviders (_Boolean_): Do we add the Master Providers from regression ? [optional = false]
        #   * *:AddRegressionSlaveProviders (_Boolean_): Do we add the Slave Providers from regression ? [optional = false]
        # * _CodeBlock_: The code called once the installer was created
        def initInstaller(iOptions = {})
          # Parse options
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Empty'
          end
          lProductRepositoryName = iOptions[:ProductRepository]
          if (lProductRepositoryName == nil)
            lProductRepositoryName = 'Empty'
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
          lContextVarsToMerge = iOptions[:ContextVars]
          
          initTestCase do

            if (lContextVarsToMerge != nil)
              @ContextVars.merge!(lContextVarsToMerge)
            end
            
            # Create the installer
            @Installer = WEACEInstall::Installer.new
            @WEACELibDir = @Installer.instance_variable_get(:@WEACELibDir)
            @WEACEEnvFile = @Installer.instance_variable_get(:@WEACEEnvFile)
            @ContextVars['WEACEEnvFile'] = @WEACEEnvFile

            # Setup the Product repository
            setupRepository(lProductRepositoryName) do

              # Create a new WEACE repository by copying the wanted one
              setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
                @WEACERepositoryDir = iTmpDir
                @ContextVars['WEACERepositoryDir'] = @WEACERepositoryDir

                # Change the installer repository location internally
                @Installer.instance_variable_set(:@WEACEInstallDir, "#{@WEACERepositoryDir}/Install")
                @Installer.instance_variable_set(:@WEACEConfigDir, "#{@WEACERepositoryDir}/Config")

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

                  # TODO: Find a way to dissociate parsing Adapters and Providers
                  if (lAddRegressionMasterAdapters or
                      lAddRegressionMasterProviders)
                    # Parse for the regression adapters
                    @Installer.send(:parseMasterPlugins)
                  end

                  # TODO: Find a way to dissociate parsing Adapters, Listeners and Providers
                  if (lAddRegressionSlaveAdapters or
                      lAddRegressionSlaveProviders or
                      lAddRegressionSlaveListeners)
                    # Parse for the regression adapters
                    @Installer.send(:parseSlavePlugins)
                  end

                  # Restore back the WEACE lib dir
                  @Installer.instance_variable_set(:@WEACELibDir, lOldWEACELibDir)
                end

                # Call client code
                yield

                # Clean installer
                @Installer = nil

                set_log_file(nil)

              end

            end
            
          end
        end

        # Check a map's content along another one.
        # Replace variables for String values before comparison.
        # Throw assertions in case of failure.
        #
        # Parameters::
        # * *iMapToEnsure* (_map_): The map used as the source comparison. Variables can be replaced here.
        # * *iMapToCheck* (_map_): The map to check against iMapToEnsure.
        def checkMap(iMapToEnsure, iMapToCheck)
          iMapToEnsure.each do |iProperty, iValue|
            if (iValue.kind_of?(String))
              if (replaceVars(iValue) != iMapToCheck[iProperty])
                log_err "Property #{iProperty} should have value #{iValue.inspect} (resolved to #{replaceVars(iValue).inspect}), but has #{iMapToCheck[iProperty]} instead."
              end
              assert_equal(replaceVars(iValue), iMapToCheck[iProperty])
            else
              if (iValue != iMapToCheck[iProperty])
                log_err "Property #{iProperty} should have value #{iValue.inspect}, but has #{iMapToCheck[iProperty].inspect} instead."
              end
              assert_equal(iValue, iMapToCheck[iProperty])
            end
          end
        end

        # Execute the installer and check its output.
        # Prerequisite: call initInstaller before.
        #
        # Parameters::
        # * *iParameters* (<em>list<String></em>): The parameters to give the installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        #   * *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        #   * *:ContextVars* (<em>map<String,String></em>): Context variables to add [optional = nil]
        #   * *:CheckComponentName* (_String_): Check that installation has been made for this Component name in case of success [optional = nil]
        #   * *:CheckInstallFile* (<em>map<Symbol,Object></em>): Check the content of the installation file in case of success. To be used with :CheckComponentName. [optional = nil]
        #   * *:CheckConfigFile* (<em>map<Symbol,Object></em>): Check the content of the configuration file in case of success. To be used with :CheckComponentName. [optional = nil]
        # * *CodeBlock*: Code executed once installation has been executed [optional = nil]
        #   * *iError* (_Exception_): Result of the installation
        def execInstaller(iParameters, iOptions, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lCheckComponentName = iOptions[:CheckComponentName]
          lCheckInstallFile = iOptions[:CheckInstallFile]
          lCheckConfigFile = iOptions[:CheckConfigFile]

          # Replace variables from @ContextVars
          lRealParams = []
          iParameters.each do |iParam|
            lRealParams << replaceVars(iParam)
          end

          # Execute
          begin
            if (debug_activated?)
              lInstallerError = @Installer.execute(['-d']+lRealParams)
            else
              lInstallerError = @Installer.execute(lRealParams)
            end
          rescue Exception
            # This way exception is shown on screen for better understanding
            assert_equal(nil, $!)
          end

          # Check
          if (lExpectedErrorClass == nil)
            if (lInstallerError != nil)
              log_err "Unexpected error: #{lInstallerError.class}: #{lInstallerError}"
              if (lInstallerError.backtrace == nil)
                log_err 'No backtrace'
              else
                log_err lInstallerError.backtrace.join("\n")
              end
            end
            assert_equal(nil, lInstallerError)
            # Check that the Component has been installed as required
            if (lCheckComponentName != nil)
              lInstallFileName = "#{@WEACERepositoryDir}/Install/InstalledComponents/#{lCheckComponentName}.inst.rb"
              assert(File.exists?(lInstallFileName))
              lConfigFileName = "#{@WEACERepositoryDir}/Config/#{lCheckComponentName}.conf.rb"
              assert(File.exists?(lConfigFileName))
              # Check the installation file's content
              if (lCheckInstallFile != nil)
                lInstallInfo = getMapFromFile(lInstallFileName)
                log_debug "Installation file info: #{lInstallInfo.inspect}"
                assert(lInstallInfo.kind_of?(Hash))
                # + 1 is due to the :InstallationDate property that is not part of the regression map
                if (lCheckInstallFile.size + 1 != lInstallInfo.size)
                  log_err "Expected the install info to be #{lCheckInstallFile.inspect}, but received #{lInstallInfo.inspect}"
                end
                assert_equal(lCheckInstallFile.size + 1, lInstallInfo.size)
                assert(lInstallInfo[:InstallationDate] != nil)
                checkMap(lCheckInstallFile, lInstallInfo)
              end
              # Check the configuration file's content
              if (lCheckConfigFile != nil)
                lConfigInfo = getMapFromFile(lConfigFileName)
                log_debug "Configuration file info: #{lConfigInfo.inspect}"
                if (lCheckConfigFile.size != lConfigInfo.size)
                  log_err "Expected the configuration info to be #{lCheckConfigFile.inspect}, but received #{lConfigInfo.inspect}"
                end
                assert_equal(lCheckConfigFile.size, lConfigInfo.size)
                checkMap(lCheckConfigFile, lConfigInfo)
              end
            end
          else
            if (lInstallerError == nil)
              log_err 'Unexpected success.'
            elsif (!lInstallerError.kind_of?(lExpectedErrorClass))
              log_err "Unexpected error: #{lInstallerError.class} (expecting #{lExpectedErrorClass}): #{lInstallerError}"
              if (lInstallerError.backtrace == nil)
                log_err 'No backtrace'
              else
                log_err lInstallerError.backtrace.join("\n")
              end
            end
            assert(lInstallerError.kind_of?(lExpectedErrorClass))
          end
          if (iCheckCode != nil)
            iCheckCode.call(lInstallerError)
          end
        end

        # Execute the WEACEInstall script with some given parameters, and check its error.
        #
        # Parmeters:
        # * *iParameters* (<em>list<String></em>): The parameters to give the installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        #   * *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        #   * *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        #   * *:ProductRepository* (_String_): Name of the Product repository to use [optional = 'Empty']
        #   * *:ContextVars* (<em>map<String,String></em>): Context variables to add [optional = nil]
        #   * *:AddRegressionMasterAdapters (_Boolean_): Do we add the Master Adapters from regression ? [optional = false]
        #   * *:AddRegressionSlaveAdapters (_Boolean_): Do we add the Slave Adapters from regression ? [optional = false]
        #   * *:AddRegressionSlaveListeners (_Boolean_): Do we add the Slave Listeners from regression ? [optional = false]
        #   * *:AddRegressionMasterProviders (_Boolean_): Do we add the Master Providers from regression ? [optional = false]
        #   * *:AddRegressionSlaveProviders (_Boolean_): Do we add the Slave Providers from regression ? [optional = false]
        #   * *:CheckComponentName* (_String_): Check that installation has been made for this Component name in case of success [optional = nil]
        #   * *:CheckInstallFile* (<em>map<Symbol,Object></em>): Check the content of the installation file in case of success. To be used with :CheckComponentName. [optional = nil]
        #   * *:CheckConfigFile* (<em>map<Symbol,Object></em>): Check the content of the configuration file in case of success. To be used with :CheckComponentName. [optional = nil]
        # * _CodeBlock_: The code called once the installer was run: [optional = nil]
        #   * *iError* (_Exception_): The error returned by the installer, or nil in case of success
        def executeInstall(iParameters, iOptions = {}, &iCheckCode)
          # Initialize
          initInstaller(iOptions) do
            # Execute
            execInstaller(iParameters, iOptions) do |iError|
              # Call additional checks from the test case itself
              if (iCheckCode != nil)
                iCheckCode.call(iError)
              end
            end
          end
        end

      end

    end

  end

end
