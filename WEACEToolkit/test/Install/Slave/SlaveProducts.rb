#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # Test everything related to installing Slave Products.
        class SlaveProducts < ::Test::Unit::TestCase

          # Test basic Component installation workflow
          include WEACE::Test::Install::GenericComponent

          # Get the specificities of this test suite to be used by GenericComponent
          # Here are the different properties to give:
          # * :InstallParameters (<em>list<String></em>): The parameters to give WEACEInstall.
          # * :InstallParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version.
          # * :ComponentName (_String_): Name of the Component to check once installed.
          # * :ComponentInstallInfo (<em>map<Symbol,Object></em>): The install info the Component should register (without :InstallationDate and :InstallationParameters).
          # * :RepositoryNormal (_String_): Name of the repository to use when installing this Component.
          # * :RepositoryInstalled (_String_): Name of the repository to use when this Component should already be installed.
          # * :RepositoryConfigured (_String_): Name of the repository to use when this Component should already be configured.
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The different properties
          def getComponentTestSpecs
            return {
              :InstallParameters => [ '--install', 'SlaveProduct', '--product', 'DummyProduct', '--as', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'SlaveProduct', '-r', 'DummyProduct', '-s', 'RegProduct' ],
              :ComponentName => 'RegProduct',
              :ComponentInstallInfo => {
                :Description => 'This Slave Product is used for regression purposes only.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :Product => 'DummyProduct',
                :Type => 'Slave'
              },
              :RepositoryNormal => 'Dummy/SlaveClientInstalled',
              :RepositoryInstalled => 'Dummy/SlaveProductInstalled',
              :RepositoryConfigured => 'Dummy/SlaveProductConfigured'
            }
          end

          # Test installing a Slave Product without --product option
          def testSlaveProductWithoutProduct
            executeInstall(['--install', 'SlaveProduct', '--as', 'RegProduct'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Product without --product argument
          def testSlaveProductWithoutProductArg
            executeInstall(['--install', 'SlaveProduct', '--as', 'RegProduct', '--product'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Product without --as option
          def testSlaveProductWithoutAs
            executeInstall(['--install', 'SlaveProduct', '--product', 'DummyProduct'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Product without --as argument
          def testSlaveProductWithoutAsArg
            executeInstall(['--install', 'SlaveProduct', '--product', 'DummyProduct', '--as'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

        end

      end

    end

  end

end
