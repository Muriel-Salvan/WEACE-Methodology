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

          # Test installing a component that was already installed
          def testComponentTwice
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Error => WEACEInstall::ComponentAlreadyInstalledError,
              :Repository => 'DummyComponentInstalled',
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing a component that was already installed with force option
          def testComponentTwiceForce
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter', '--force'],
              :Error => WEACEInstall::MissingWEACEMasterServerError,
              :Repository => 'DummyComponentInstalled',
              :AddRegressionMasterAdapters => true
            )
          end





          # Test installing the Master Server without specifying any provider
          def testMasterServerWithoutProvider
            executeInstall(['--install', 'Master/Server/WEACEMasterServer'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing the Master Server with specifying a missing provider
          def testMasterServerWithMissingProvider
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing the Master Server with specifying an unknown provider
          def testMasterServerWithUnknownProvider
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::MasterProviderError)
          end

          # Test installing the Master Server
          def testMasterServer
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProvider'],
              :AddRegressionMasterProviders => true
            )
          end




          # Test installing the Slave Client without specifying any provider
          def testSlaveClientWithoutProvider
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing the Slave Client with specifying a missing provider
          def testSlaveClientWithMissingProvider
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider'], :Error => WEACEInstall::CommandLineError)
          end

          # Test installing the Slave Client with specifying an unknown provider
          def testSlaveClientWithUnknownProvider
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::SlaveProviderError)
          end

          # Test installing the Slave Client
          def testSlaveClient
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProvider'],
              :AddRegressionSlaveProviders => true
            )
          end




          # Test installing a Master Adapter without the Master Server
          def testMasterAdapterWithoutServer
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Error => WEACEInstall::MissingWEACEMasterServerError,
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing a Slave Adapter without the Slave Client
          def testSlaveAdapterWithoutClient
            executeInstall(['--install', 'Slave/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Error => WEACEInstall::MissingWEACESlaveClientError,
              :AddRegressionSlaveAdapters => true
            )
          end

          # Test installing a Slave Listener without the Slave Client
          def testSlaveListenerWithoutClient
            executeInstall(['--install', 'Slave/Listeners/DummyListener'],
              :Error => WEACEInstall::MissingWEACESlaveClientError,
              :AddRegressionSlaveListeners => true
            )
          end

          # Test installing a Master Adapter with the Master Server

          # Test installing a Slave Adapter with the Slave Client

          # Test installing a Slave Listener with the Slave Client

        end

      end

    end

  end

end
