#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Global

        # Test everything related to installing components.
        class Install < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing an unknown component
          def testUnknownComponent
            executeInstall(['--install', 'UnknownComponentNameForTest'], :Error => WEACEInstall::UnknownComponentError)
          end

          # Test installing the Master Server without specifying any provider
          def testMasterServerWithoutProvider
            executeInstall(['--install', 'Master/Server/WEACEMasterServer'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing the Master Server with specifying a missing provider
          def testMasterServerWithMissingProvider
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing a component that was already installed
          def testInstallComponentTwice
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Error => WEACEInstall::ComponentAlreadyInstalledError,
              :Repository => 'DummyComponentInstalled',
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing a component that was already installed with force option
          def testInstallComponentTwiceForce
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter', '--force'],
              :Error => WEACEInstall::MissingWEACEMasterServerError,
              :Repository => 'DummyComponentInstalled',
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing the Master Server with specifying an unknown provider

          # Test installing the Master Server

          # Test installing the Slave Client

          # Test installing the Slave Client without specifying any provider

          # Test installing the Slave Client with specifying a missing provider

          # Test installing the Slave Client with specifying an unknown provider

          # Test installing a Master Adapter without the Master Server

          # Test installing a Slave Adapter without the Slave Client

          # Test installing a Slave Listener without the Slave Client

          # Test installing a Master Adapter with the Master Server

          # Test installing a Slave Adapter with the Slave Client

          # Test installing a Slave Listener with the Slave Client

        end

      end

    end

  end

end
