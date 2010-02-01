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
          def testMasterProductWithoutServer
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

        end

      end

    end

  end

end
