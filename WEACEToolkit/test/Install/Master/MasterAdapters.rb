#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Adapters.
        class MasterAdapters < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing a Master Adapter without the Master Server
          def testMasterAdapterWithoutServer
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Error => WEACEInstall::MissingWEACEMasterServerError,
              :AddRegressionMasterAdapters => true
            )
          end

          # Test installing a Master Adapter
          def testMasterAdapter
            executeInstall(['--install', 'Master/Adapters/DummyProduct/DummyTool/DummyAdapter'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true
            )
          end

        end

      end

    end

  end

end
