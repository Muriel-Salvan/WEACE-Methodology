#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Products.
        # Don't test each Master Product here. Just the generic functionalities with Dummy MasterProducts.
        class MasterProducts < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing a Master Product without the Master Server
          def testMasterProductWithoutServer
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Error => WEACEInstall::Installer::MissingWEACEMasterServerError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product
          def testMasterProduct
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProduct',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_Calls]
              )
            end
          end

          # Test installing a Master Product (short version)
          def testMasterProductShort
            executeInstall(['--install', 'MasterProduct', '-r', 'DummyProduct', '-s', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProduct',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_Calls]
              )
            end
          end

          # Test installing a Master Product twice
          def testMasterProductTwice
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Installer::AlreadyInstalledComponentError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product twice with force option
          def testMasterProductTwiceForce
            executeInstall(['--install', 'MasterProduct', '--force', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProduct',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_Calls]
              )
            end
          end

          # Test installing a Master Product twice with force option (short version)
          def testMasterProductTwiceForceShort
            executeInstall(['--install', 'MasterProduct', '-f', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProduct',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProduct_Calls]
              )
            end
          end

          # Test installing a Master Product without --product option
          def testMasterProductWithoutProduct
            executeInstall(['--install', 'MasterProduct', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --product argument
          def testMasterProductWithoutProductArg
            executeInstall(['--install', 'MasterProduct', '--as', 'RegProduct', '--product'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --as option
          def testMasterProductWithoutAs
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --as argument
          def testMasterProductWithoutAsArg
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product missing parameters
          def testMasterProductWithoutParameters
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductWithParams', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProductWithParams_Calls])
            end
          end

          # Test installing a Master Product with Parameters
          def testMasterProductWithParameters
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductWithParams', '--as', 'RegProduct', '--', '--dummyflag'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '--dummyflag',
                :Product => 'DummyProductWithParams',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProductWithParams_Calls]
              )
              assert_equal(true, $Variables[:DummyProductWithParams_DummyFlag])
            end
          end

          # Test installing a Master Product missing parameters values
          def testMasterProductWithoutParametersValues
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductWithParamsValues', '--as', 'RegProduct', '--', '--dummyvar'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProductWithParamsValues_Calls])
            end
          end

          # Test installing a Master Product with Parameters values
          def testMasterProductWithParametersValues
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductWithParamsValues', '--as', 'RegProduct', '--', '--dummyvar', 'testvalue'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '--dummyvar testvalue',
                :Product => 'DummyProductWithParamsValues',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProductWithParamsValues_Calls]
              )
              assert_equal('testvalue', $Variables[:DummyProductWithParamsValues_DummyVar])
            end
          end

          # Test installing a Master Product with additional Parameters
          def testMasterProductWithAdditionalParameters
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct', '--', '--', '--dummyflag'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '-- --dummyflag',
                :Product => 'DummyProduct',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProduct_Calls]
              )
              assert_equal(['--dummyflag'], $Variables[:DummyProduct_AdditionalParams])
            end
          end

          # Test installing a Master Product with check failing
          def testMasterProductWithCheckFail
            # Define the exception to be able to use it as a parameter
            WEACEInstall::module_eval("
module Master
  module Adapters
    class DummyProductCheckFail
      class CheckError < RuntimeError
      end
    end
  end
end
"
            )
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductCheckFail', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Master::Adapters::DummyProductCheckFail::CheckError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:DummyProductCheckFail_Calls]
              )
            end
          end

          # Test installing a Master Product with execute failing
          def testMasterProductWithExecFail
            # Define the exception to be able to use it as a parameter
            WEACEInstall::module_eval("
module Master
  module Adapters
    class DummyProductExecFail
      class ExecError < RuntimeError
      end
    end
  end
end
"
            )
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductExecFail', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Master::Adapters::DummyProductExecFail::ExecError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProductExecFail_Calls]
              )
            end
          end

          # Test installing a Master Product with no check
          def testMasterProductNoCheck
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductNoCheck', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProductNoCheck',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'execute', [] ],
                  [ 'getDefaultConfig', [] ]
                ],
                $Variables[:DummyProductNoCheck_Calls]
              )
            end
          end

          # Test installing a Master Product with no execute
          def testMasterProductNoExec
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductNoExec', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::Installer::MissingExecuteError
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ]
                ],
                $Variables[:DummyProductNoExec_Calls]
              )
            end
          end

          # Test installing a Master Product with no default configuration
          def testMasterProductNoDefaultConf
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProductNoDefaultConf', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProductNoDefaultConf',
                :Type => 'Master'
               },
              :CheckConfigFile => {}
            ) do |iError|
              assert_equal(
                [
                  [ 'check', [] ],
                  [ 'execute', [] ]
                ],
                $Variables[:DummyProductNoDefaultConf_Calls]
              )
            end
          end

          # Test installing a Master Product with its configuration already written
          def testMasterProductAlreadyConfigured
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct'],
              :Repository => 'MasterProductConfigured',
              :AddRegressionMasterAdapters => true,
              :CheckComponentName => 'RegProduct',
              :CheckInstallFile => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :InstallationParameters => '',
                :Product => 'DummyProduct',
                :Type => 'Master'
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
                $Variables[:DummyProduct_Calls]
              )
            end
          end

        end

      end

    end

  end

end
