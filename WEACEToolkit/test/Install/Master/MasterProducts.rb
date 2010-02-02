#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Products.
        # Don't test each Master Product here. Just the generic functionalities with Dummy MasterProducts.
        class MasterProducts < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

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
              :InstallParameters => [ '--install', 'MasterProduct', '--product', 'DummyProduct', '--as', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'MasterProduct', '-r', 'DummyProduct', '-s', 'RegProduct' ],
              :ComponentName => 'RegProduct',
              :ComponentInstallInfo => {
                :Description => 'Dummy Product used in WEACE Regression.',
                :Author => 'murielsalvan@users.sourceforge.net',
                :Product => 'DummyProduct',
                :Type => 'Master'
              },
              :RepositoryNormal => 'MasterServerInstalled',
              :RepositoryInstalled => 'MasterProductInstalled',
              :RepositoryConfigured => 'MasterProductConfigured'
            }
          end

          # Test installing a Master Product without --product option
          def testMasterProductWithoutProduct
            executeInstall(['--install', 'MasterProduct', '--as', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --product argument
          def testMasterProductWithoutProductArg
            executeInstall(['--install', 'MasterProduct', '--as', 'RegProduct', '--product'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --as option
          def testMasterProductWithoutAs
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

          # Test installing a Master Product without --as argument
          def testMasterProductWithoutAsArg
            executeInstall(['--install', 'MasterProduct', '--product', 'DummyProduct', '--as'],
              :Repository => 'MasterServerInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_Calls])
            end
          end

        end

      end

    end

  end

end
