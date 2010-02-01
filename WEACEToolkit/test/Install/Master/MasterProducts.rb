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

        end

      end

    end

  end

end
