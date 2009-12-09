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
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::ProviderError)
          end

          # Test installing the Master Server
          def testMasterServer
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProvider'],
              :AddRegressionMasterProviders => true
            ) do |iError|
              # Check that the environment has been created correctly
              lEnvFileName = "#{@RepositoryDir}/Config/Master_Env.rb"
              assert(File.exists?(lEnvFileName))
              lEnv = nil
              File.open(lEnvFileName, 'r') do |iFile|
                lEnv = eval(iFile.read)
              end
              assert_equal('Master', lEnv[:ProviderType])
              assert_equal('DummyMasterProvider', lEnv[:ProviderID])
              assert_equal([], lEnv[:Parameters])
            end
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
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::ProviderError)
          end

          # Test installing the Slave Client
          def testSlaveClient
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProvider'],
              :AddRegressionSlaveProviders => true
            ) do |iError|
              # Check that the environment has been created correctly
              lEnvFileName = "#{@RepositoryDir}/Config/Slave_Env.rb"
              assert(File.exists?(lEnvFileName))
              lEnv = nil
              File.open(lEnvFileName, 'r') do |iFile|
                lEnv = eval(iFile.read)
              end
              assert_equal('Slave', lEnv[:ProviderType])
              assert_equal('DummySlaveProvider', lEnv[:ProviderID])
              assert_equal([], lEnv[:Parameters])
            end
          end

          # Test installing the Slave Client with a Provider missing some parameters
          def testSlaveClientWithProviderMissingParameters
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProviderWithParams'],
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionSlaveProviders => true
            ) do |iError|
              assert_equal(nil, $Variables[:SlaveProviderDummyFlag])
            end
          end

          # Test installing the Slave Client with a Provider missing some parameters values
          def testSlaveClientWithProviderMissingParametersValues
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProviderWithParamsValues', '--', '--dummyvar'],
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionSlaveProviders => true
            ) do |iError|
              assert_equal(nil, $Variables[:SlaveProviderDummyVar])
            end
          end

          # Test installing the Master Server with a Provider missing some parameters
          def testMasterServerWithProviderMissingParameters
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithParams'],
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionMasterProviders => true
            ) do |iError|
              assert_equal(nil, $Variables[:MasterProviderDummyFlag])
            end
          end

          # Test installing the Master Server with a Provider missing some parameters values
          def testMasterServerWithProviderMissingParametersValues
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithParamsValues', '--', '--dummyvar'],
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionMasterProviders => true
            ) do |iError|
              assert_equal(nil, $Variables[:MasterProviderDummyVar])
            end
          end

          # Test installing the Slave Client with a Provider having some parameters
          def testSlaveClientWithProviderHavingParameters
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProviderWithParams', '--', '--flag'],
              :AddRegressionSlaveProviders => true
            ) do |iError|
              assert_equal(true, $Variables[:SlaveProviderDummyFlag])
            end
          end

          # Test installing the Slave Client with a Provider having some parameters values
          def testSlaveClientWithProviderHavingParametersValues
            executeInstall(['--install', 'Slave/Client/WEACESlaveClient', '--', '--provider', 'DummySlaveProviderWithParamsValues', '--', '--dummyvar', 'testvalue'],
              :AddRegressionSlaveProviders => true
            ) do |iError|
              assert_equal('testvalue', $Variables[:SlaveProviderDummyVar])
            end
          end

          # Test installing the Master Server with a Provider having some parameters
          def testMasterServerWithProviderHavingParameters
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithParams', '--', '--flag'],
              :AddRegressionMasterProviders => true
            ) do |iError|
              assert_equal(true, $Variables[:MasterProviderDummyFlag])
            end
          end

          # Test installing the Master Server with a Provider having some parameters values
          def testMasterServerWithProviderHavingParametersValues
            executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithParamsValues', '--', '--dummyvar', 'testvalue'],
              :AddRegressionMasterProviders => true
            ) do |iError|
              assert_equal('testvalue', $Variables[:MasterProviderDummyVar])
            end
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

          # Test installing a Master Adapter
          def testMasterAdapter
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing a Slave Adapter
          def testSlaveAdapter
            executeInstall(['--install', 'Slave/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Repository => 'SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true
            )
          end

          # Test installing a Slave Listener
          def testSlaveListener
            executeInstall(['--install', 'Slave/Listeners/DummyListener'],
              :Repository => 'SlaveClientInstalled',
              :AddRegressionSlaveListeners => true
            )
          end




          # Test installing a Component missing some parameters
          def testComponentWithMissingParameters
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapterWithParameters'],
              :Repository => 'MasterServerInstalled',
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:MasterAdapterDummyFlag])
            end
          end

          # Test installing a Component missing some parameters values
          def testComponentWithMissingParametersValues
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapterWithParametersValues', '--', '--dummyvar'],
              :Repository => 'MasterServerInstalled',
              :Error => WEACEInstall::CommandLineError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:MasterAdapterDummyVar])
            end
          end

          # Test installing a Component having some parameters
          def testComponentHavingParameters
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapterWithParameters', '--', '--dummyflag'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(true, $Variables[:MasterAdapterDummyFlag])
            end
          end

          # Test installing a Component having some parameters values
          def testComponentHavingParametersValues
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapterWithParametersValues', '--', '--dummyvar', 'testvalue'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal('testvalue', $Variables[:MasterAdapterDummyVar])
            end
          end

        end

      end

    end

  end

end
