#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # Test everything related to installing Slave Actions.
        class SlaveActions < ::Test::Unit::TestCase

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
              :InstallParameters => [ '--install', 'SlaveAction', '--action', 'DummyAction', '--tool', 'DummyTool', '--on', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'SlaveAction', '-a', 'DummyAction', '-t', 'DummyTool', '-o', 'RegProduct' ],
              :ComponentName => 'RegProduct.DummyTool.DummyAction',
              :ComponentInstallInfo => {
                :Description => 'This Slave Action is used for regression purposes only.',
                :Author => 'murielsalvan@users.sourceforge.net'
              },
              :RepositoryNormal => 'Dummy/SlaveToolInstalled',
              :RepositoryInstalled => 'Dummy/SlaveActionInstalled',
              :RepositoryConfigured => 'Dummy/SlaveActionConfigured'
            }
          end

          # Test installing a Slave Action without --action option
          def testSlaveActionWithoutAction
            executeInstall(['--install', 'SlaveAction', '--on', 'RegProduct', '--tool', 'DummyTool'],
              :Repository => 'Dummy/SlaveToolInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Action without --action argument
          def testSlaveActionWithoutActionArg
            executeInstall(['--install', 'SlaveAction', '--on', 'RegProduct', '--tool', 'DummyTool', '--action'],
              :Repository => 'Dummy/SlaveToolInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Action without --tool option
          def testSlaveActionWithoutTool
            executeInstall(['--install', 'SlaveAction', '--action', 'DummyAction', '--on', 'RegProduct'],
              :Repository => 'Dummy/SlaveToolInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Action without --tool argument
          def testSlaveActionWithoutToolArg
            executeInstall(['--install', 'SlaveAction', '--action', 'DummyAction', '--on', 'RegProduct', '--tool'],
              :Repository => 'Dummy/SlaveToolInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Action without --on option
          def testSlaveActionWithoutOn
            executeInstall(['--install', 'SlaveAction', '--action', 'DummyAction', '--tool', 'DummyTool'],
              :Repository => 'Dummy/SlaveToolInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Action without --on argument
          def testSlaveActionWithoutOnArg
            executeInstall(['--install', 'SlaveAction', '--action', 'DummyAction', '--tool', 'DummyTool', '--on'],
              :Repository => 'Dummy/SlaveToolInstalled',
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
