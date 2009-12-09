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
