#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Adapters

          # Test everything related to installing Slave Adapters.
          class SlaveAdapters < ::Test::Unit::TestCase

            include WEACE::Test::Install::Common

            # Test installing a Slave Adapter without the Slave Client
            def testSlaveAdapterWithoutClient
              executeInstall(['--install', 'Slave/Adapters/DummyProduct/DummyTool/DummyAdapter'],
                :Error => WEACEInstall::MissingWEACESlaveClientError,
                :AddRegressionSlaveAdapters => true
              )
            end

            # Test installing a Slave Adapter
            def testSlaveAdapter
              executeInstall(['--install', 'Slave/Adapters/DummyProduct/DummyTool/DummyAdapter'],
                :Repository => 'SlaveClientInstalled',
                :AddRegressionSlaveAdapters => true
              ) do |iError|
                assert_equal(true, $Variables[:DummyAdapterInstall])
              end
            end

          end

        end

      end

    end

  end

end
