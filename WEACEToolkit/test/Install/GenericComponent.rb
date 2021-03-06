#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      # This module is included by every test suite that wants to automatically add test cases validating the process flow of Component's installation
      module GenericComponent

        include WEACE::Test::Install::Common

        # Initialize a test case for a generic Component
        #
        # Parameters::
        # * *CodeBlock*: The code to call once it is initialized
        def initComponentTest
          initTestCase do
            # Get test suite specificities
            @Specs = replaceObjectVars(getComponentTestSpecs)
            # Complete specs
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
              assert_equal(nil, $Variables[:ComponentInstall])
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
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
              assert_equal(nil, $Variables[:ComponentInstall])
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
              )
            end
          end
        end

        # Test installing the Component with missing parameters
        def testComponentWithoutParameters
          initComponentTest do
            $Context[:ComponentInstall] = {
              :AddFlagParameter => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component with Parameters
        def testComponentWithParameters
          initComponentTest do
            $Context[:ComponentInstall] = {
              :AddFlagParameter => true
            }
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyflag'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
              )
              assert_equal(true, $Variables[:ComponentInstall][:DummyFlag])
            end
          end
        end

        # Test installing the Component, missing parameters values
        def testComponentWithoutParametersValues
          initComponentTest do
            $Context[:ComponentInstall] = {
              :AddVarParameter => true
            }
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyvar'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component with Parameters values
        def testComponentWithParametersValues
          initComponentTest do
            $Context[:ComponentInstall] = {
              :AddVarParameter => true
            }
            executeInstall(@Specs[:InstallParameters] + ['--', '--dummyvar', 'testvalue'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
              )
              assert_equal('testvalue', $Variables[:ComponentInstall][:DummyVar])
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
              )
              assert_equal(['--dummyflag'], $Variables[:ComponentInstall][:AdditionalParams])
            end
          end
        end

        # Test installing the Component with check failing
        def testComponentWithCheckFail
          initComponentTest do
            $Context[:ComponentInstall] = {
              :CheckFail => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::Installer::CheckError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
              )
              assert(iError.CheckError.is_a?(WEACE::Test::Install::GenericComponentTestBody::CheckError))
            end
          end
        end

        # Test installing the Component with execute failing
        def testComponentWithExecFail
          initComponentTest do
            $Context[:ComponentInstall] = {
              :ExecFail => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACE::Test::Install::GenericComponentTestBody::ExecError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
              )
            end
          end
        end

        # Test installing the Component with no check
        def testComponentNoCheck
          initComponentTest do
            $Context[:ComponentInstall] = {
              :NoCheck => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
              )
            end
          end
        end

        # Test installing the Component with no execute
        def testComponentNoExec
          initComponentTest do
            $Context[:ComponentInstall] = {
              :NoExec => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::Installer::MissingExecuteError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
              )
            end
          end
        end

        # Test installing the Component with no default configuration
        def testComponentNoDefaultConf
          initComponentTest do
            $Context[:ComponentInstall] = {
              :NoDefaultConf => true
            }
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
                :InstallationParameters => ''
               } ),
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:ComponentInstall][:Calls]
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
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
              )
            end
          end
        end

        # Test installing the Component, adding invalid parameter among install parameters
        def testComponentWithInvalidParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['Regression_InvalidParameter'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --provider option
        def testComponentWithExtraProviderParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--provider', 'DummyProvider'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --product option
        def testComponentWithExtraProductParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--product', 'DummyProduct'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --as option
        def testComponentWithExtraAsParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--as', 'RegProduct'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --process option
        def testComponentWithExtraProcessParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--process', 'DummyProcess'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --tool option
        def testComponentWithExtraToolParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--tool', 'DummyTool'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --action option
        def testComponentWithExtraActionParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--action', 'DummyAction'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --listener option
        def testComponentWithExtraListenerParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--listener', 'DummyListener'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test installing the Component, adding extra --on option
        def testComponentWithExtraOnParam
          initComponentTest do
            executeInstall(@Specs[:InstallParameters] + ['--on', 'RegProduct'],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end
        end

        # Test that the Component has the Provider environment correctly set
        def testComponentProviderEnv
          initComponentTest do
            executeInstall(@Specs[:InstallParameters],
              :Repository => @Specs[:RepositoryNormal],
              @Specs[:AddRegressionAdaptersVar] => true,
              :CheckComponentName => @Specs[:ComponentName],
              :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                $Variables[:ComponentInstall][:Calls]
              )
              assert_equal(@Specs[:ProviderEnv], $Variables[:ComponentInstall][:ProviderEnv])
            end
          end
        end

        # Test that the Component has the Product Config correctly set
        def testComponentProductConfig
          initComponentTest do
            if (@Specs[:ProductConfig] != nil)
              executeInstall(@Specs[:InstallParameters],
                :Repository => @Specs[:RepositoryProductConfig],
                @Specs[:AddRegressionAdaptersVar] => true,
                :CheckComponentName => @Specs[:ComponentName],
                :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                  $Variables[:ComponentInstall][:Calls]
                )
                assert_equal(@Specs[:ProductConfig], $Variables[:ComponentInstall][:ProductConfig])
              end
            end
          end
        end

        # Test that the Component has the Tool Config correctly set
        def testComponentToolConfig
          initComponentTest do
            if (@Specs[:ToolConfig] != nil)
              executeInstall(@Specs[:InstallParameters],
                :Repository => @Specs[:RepositoryToolConfig],
                @Specs[:AddRegressionAdaptersVar] => true,
                :CheckComponentName => @Specs[:ComponentName],
                :CheckInstallFile => @Specs[:ComponentInstallInfo].merge( {
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
                  $Variables[:ComponentInstall][:Calls]
                )
                assert_equal(@Specs[:ToolConfig], $Variables[:ComponentInstall][:ToolConfig])
              end
            end
          end
        end

      end

    end

  end

end
