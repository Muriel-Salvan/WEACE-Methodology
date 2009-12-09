#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Server

          # Test everything related to installing WEACE Master Server.
          class WEACEMasterServer < ::Test::Unit::TestCase

            include WEACE::Test::Install::Common

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

          end

        end

      end

    end

  end

end
