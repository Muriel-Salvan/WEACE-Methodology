#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      # This module is included by every test suite that wants to automatically add test cases validating the process flow of Component's installation
      module GenericComponent

        # Initialize a test case for a generic Component
        #
        # Parameters:
        # * *iComponentSuffix* (_String_): Component suffix to apply [optional = '']
        # * *CodeBlock*: The code to call once it is initialized
        def initComponentTest(iComponentSuffix = '')
          initTestCase do
            @ContextVars['ComponentSuffix'] = iComponentSuffix
            # Get test suite specificities
            @Specs = replaceObjectVars(getComponentTestSpecs)
            # Complete specs
            @Specs[:CallsVar] = @Specs[:CallsVarName].to_sym
            @Specs[:DummyFlagVar] = @Specs[:DummyFlagVarName].to_sym
            @Specs[:DummyVarVar] = @Specs[:DummyVarVarName].to_sym
            @Specs[:AdditionalParamsVar] = @Specs[:AdditionalParamsVarName].to_sym
            if (@Type == 'Master')
              @Specs[:MissingMainError] = WEACEInstall::Installer::MissingWEACEMasterServerError
              @Specs[:AddRegressionAdaptersVar] = :AddRegressionMasterAdapters
            else
              @Specs[:MissingMainError] = WEACEInstall::Installer::MissingWEACESlaveClientError
              @Specs[:AddRegressionAdaptersVar] = :AddRegressionSlaveAdapters
            end
            yield
          end
        end

        # Test installing a Component without its main Component (MasterServer or SlaveClient)
        def testComponentWithoutMain
          initComponentTest do
            executeInstall(@Specs[:InstallParameters],
              :Error => @Specs[:MissingMainError],
              @Specs[:AddRegressionAdaptersVar] => true
            ) do |iError|
              assert_equal(nil, $Variables[@Specs[:CallsVar]])
            end
          end
        end

        # Test installing the Component in a nominal case
        def testComponent
          initComponentTest do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component in a nominal case (short version)
        def testComponentShort
          initComponentTest do
            executeInstall(@Specs[:InstallParametersShort],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component twice
        def testComponentTwice
          initComponentTest do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryInstalled],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::Installer::AlreadyInstalledComponentError
            ) do |iError|
              assert_equal(nil, $Variables[@Specs[:CallsVar]])
            end
          end
        end

        # Test installing the Component twice with force option
        def testComponentTwiceForce
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--force'],
              :Repository => @Specs[:RepositoryInstalled],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component twice with force option (short version)
        def testComponentTwiceForceShort
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['-f'],
              :Repository => @Specs[:RepositoryInstalled],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component with missing parameters
        def testComponentWithoutParameters
          initComponentTest('WithParams') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[@Specs[:CallsVar]])
              assert_equal(nil, $Variables[@Specs[:DummyFlagVar]])
            end
          end
        end

        # Test installing the Component with Parameters
        def testComponentWithParameters
          initComponentTest('WithParams') do
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyflag'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => '--dummyflag'
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
              assert_equal(true, $Variables[@Specs[:DummyFlagVar]])
            end
          end
        end

        # Test installing the Component, missing parameters values
        def testComponentWithoutParametersValues
          initComponentTest('WithParamsValues') do
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyvar'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[@Specs[:CallsVar]])
              assert_equal(nil, $Variables[@Specs[:DummyVarVar]])
            end
          end
        end

        # Test installing the Component with Parameters values
        def testComponentWithParametersValues
          initComponentTest('WithParamsValues') do
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyvar', 'testvalue'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => '--dummyvar testvalue'
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
              assert_equal('testvalue', $Variables[@Specs[:DummyVarVar]])
            end
          end
        end

        # Test installing the Component with additional Parameters
        def testComponentWithAdditionalParameters
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--', '--', '--dummyflag'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => '-- --dummyflag'
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
              assert_equal(['--dummyflag'], $Variables[@Specs[:AdditionalParamsVar]])
            end
          end
        end

        # Test installing the Component with check failing
        def testComponentWithCheckFail
          initComponentTest('CheckFail') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::Installer::CheckError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
              assert(iError.CheckError.is_a?(@Specs[:CheckFailErrorClass]))
            end
          end
        end

        # Test installing the Component with execute failing
        def testComponentWithExecFail
          initComponentTest('ExecFail') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => @Specs[:ExecFailErrorClass]
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component with no check
        def testComponentNoCheck
          initComponentTest('NoCheck') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component with no execute
        def testComponentNoExec
          initComponentTest('NoExec') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::Installer::MissingExecuteError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component with no default configuration
        def testComponentNoDefaultConf
          initComponentTest('NoDefaultConf') do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

        # Test installing the Component with its configuration already written
        def testComponentAlreadyConfigured
          initComponentTest do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryConfigured],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:AdditionalComponentInstall].merge( {
                :Description => @Specs[:ComponentDescription],
                :Author => @Specs[:ComponentAuthor],
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {
                :PersonalizedAttribute => 'PersonalizedValue'
              }
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[@Specs[:CallsVar]]
              )
            end
          end
        end

      end

    end

  end

end
