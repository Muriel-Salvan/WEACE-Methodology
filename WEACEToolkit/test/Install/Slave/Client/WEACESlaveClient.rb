#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Client

          # Test everything related to installing WEACE Slave Client.
          class Install < ::Test::Unit::TestCase

            include WEACE::Test::Install::Common

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
                lEnvFileName = "#{@WEACERepositoryDir}/Config/Slave_Env.rb"
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

          end

        end

      end

    end

  end

end
