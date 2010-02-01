#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Processes.
        # Don't test each Master Product here. Just the generic functionalities with Dummy MasterProcesses.
        class MasterProcesses < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing a Master Process without the Master Server
          def testMasterProcessWithoutServer
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Error => WEACEInstall::Installer::MissingWEACEMasterServerError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without the Master Product
          def testMasterProcessWithoutMasterProduct
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :Error => WEACEInstall::Installer::MissingMasterProductError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process
          def testMasterProcess
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
            end
          end

          # Test installing a Master Process (short version)
          def testMasterProcessShort
            executeInstall(['--install', 'MasterProcess', '-c', 'DummyProcess', '-o', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
            end
          end

          # Test installing a Master Process twice
          def testMasterProcessTwice
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProcessInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Installer::AlreadyInstalledComponentError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process twice with force option
          def testMasterProcessTwiceForce
            executeInstall(['--install', 'MasterProcess', '--force', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProcessInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
            end
          end

          # Test installing a Master Process twice with force option (short version)
          def testMasterProcessTwiceForceShort
            executeInstall(['--install', 'MasterProcess', '-f', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProcessInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
            end
          end

          # Test installing a Master Process without --process option
          def testMasterProcessWithoutProcess
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process argument
          def testMasterProcessWithoutProcessArg
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct', '--process'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on option
          def testMasterProcessWithoutOn
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on argument
          def testMasterProcessWithoutOnArg
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Product missing parameters
          def testMasterProcessWithoutParameters
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessWithParams', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcessWithParams_Calls])
            end
          end

          # Test installing a Master Product with Parameters
          def testMasterProcessWithParameters
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessWithParams', '--on', 'RegProduct', '--', '--dummyflag'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcessWithParams',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '--dummyflag'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessWithParams_Calls]
              )
              assert_equal(true, $Variables[:DummyProduct_DummyProcessWithParams_DummyFlag])
            end
          end

          # Test installing a Master Product missing parameters values
          def testMasterProcessWithoutParametersValues
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessWithParamsValues', '--on', 'RegProduct', '--', '--dummyvar'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcessWithParamsValues_Calls])
            end
          end

          # Test installing a Master Product with Parameters values
          def testMasterProcessWithParametersValues
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessWithParamsValues', '--on', 'RegProduct', '--', '--dummyvar', 'testvalue'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcessWithParamsValues',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '--dummyvar testvalue'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessWithParamsValues_Calls]
              )
              assert_equal('testvalue', $Variables[:DummyProduct_DummyProcessWithParamsValues_DummyVar])
            end
          end

          # Test installing a Master Product with additional Parameters
          def testMasterProcessWithAdditionalParameters
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct', '--', '--', '--dummyflag'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '-- --dummyflag'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
              assert_equal(['--dummyflag'], $Variables[:DummyProduct_DummyProcess_AdditionalParams])
            end
          end

          # Test installing a Master Product with check failing
          def testMasterProcessWithCheckFail
            # Define the exception to be able to use it as a parameter
            WEACEInstall::module_eval("
module Master
  module Adapters
    class DummyProduct
      class DummyProcessCheckFail
        class CheckError < RuntimeError
        end
      end
    end
  end
end
"
            )
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessCheckFail', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Master::Adapters::DummyProduct::DummyProcessCheckFail::CheckError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessCheckFail_Calls]
              )
            end
          end

          # Test installing a Master Product with execute failing
          def testMasterProcessWithExecFail
            # Define the exception to be able to use it as a parameter
            WEACEInstall::module_eval("
module Master
  module Adapters
    class DummyProduct
      class DummyProcessExecFail
        class ExecError < RuntimeError
        end
      end
    end
  end
end
"
            )
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessExecFail', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Master::Adapters::DummyProduct::DummyProcessExecFail::ExecError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessExecFail_Calls]
              )
            end
          end

          # Test installing a Master Product with no check
          def testMasterProcessNoCheck
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessNoCheck', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcessNoCheck',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessNoCheck_Calls]
              )
            end
          end

          # Test installing a Master Product with no execute
          def testMasterProcessNoExec
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessNoExec', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Installer::MissingExecuteError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessNoExec_Calls]
              )
            end
          end

          # Test installing a Master Product with no default configuration
          def testMasterProcessNoDefaultConf
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcessNoDefaultConf', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcessNoDefaultConf',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls]
              )
            end
          end

          # Test installing a Master Product with its configuration already written
          def testMasterProcessAlreadyConfigured
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProcessConfigured',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct.DummyProcess',
              :CheckInstallFile => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => ''
               },
              :CheckConfigFile => {
                :PersonalizedAttribute => 'PersonalizedValue'
              }
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_DummyProcess_Calls]
              )
            end
          end

        end

      end

    end

  end

end
