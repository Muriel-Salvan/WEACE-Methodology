#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # Test everything related to installing Slave Listeners.
        class SlaveListeners < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing a Slave Listener without the Slave Client
          def testSlaveListenerWithoutClient
            executeInstall(['--install', 'Slave/Listeners/DummyListener'],
              :Error => WEACEInstall::MissingWEACESlaveClientError,
              :AddRegressionSlaveListeners => true
            )
          end

          # Test installing a Slave Listener
          def testSlaveListener
            executeInstall(['--install', 'Slave/Listeners/DummyListener'],
              :Repository => 'SlaveClientInstalled',
              :AddRegressionSlaveListeners => true
            ) do |iError|
              assert_equal(true, $Variables[:DummyListenerInstall])
            end
          end

        end

      end

    end

  end

end
