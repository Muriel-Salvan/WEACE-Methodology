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
          # For some properties, use %{ComponentSuffix} to indicate where to insert the suffixes for various tests (NoCheck, ExecFail, WithParams...)
          # Here are the different properties to give:
          # * :InstallParameters (<em>list<String></em>): The parameters to give WEACEInstall (use %{ComponentSuffix}).
          # * :InstallParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version (use %{ComponentSuffix}).
          # * :ComponentName (_String_): Name of the Component to check once installed (use %{ComponentSuffix}).
          # * :ComponentDescription (_String_): Component's description.
          # * :ComponentAuthor (_String_): Component's author.
          # * :AdditionalComponentInstall (<em>map<Symbol,Object></em>): Additional properties that should be among the installation file (use %{ComponentSuffix}).
          # * :RepositoryNormal (_String_): Name of the repository to use when installing this Component.
          # * :RepositoryInstalled (_String_): Name of the repository to use when this Component should already be installed.
          # * :RepositoryConfigured (_String_): Name of the repository to use when this Component should already be configured.
          # * :CallsVarName (_String_): Name of the variable to be used to check for Component's calls (use %{ComponentSuffix}).
          # * :DummyFlagVarName (_String_): Name of the variable to be used to check for Component's DummyFlag (use %{ComponentSuffix}).
          # * :DummyVarVarName (_String_): Name of the variable to be used to check for Component's DummyVar (use %{ComponentSuffix}).
          # * :AdditionalParamsVarName (_String_): Name of the variable to be used to check for Component's additional parameters (use %{ComponentSuffix}).
          # * :CheckFailErrorClass (_class_): Class of the underlying error returned by the CheckFail version of the Component.
          # * :ExecFailErrorClass (_class_): Class of the underlying error returned by the ExecFail version of the Component.
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The different properties
          def getComponentTestSpecs
              # Define the exceptions to be able to use them as parameters before requiring their plugin
              WEACEInstall::module_eval("
module Master
  module Adapters
    class DummyProductCheckFail
      class CheckError < RuntimeError
      end
    end
    class DummyProductExecFail
      class ExecError < RuntimeError
      end
    end
  end
end
"
              )
            return {
              :InstallParameters => [ '--install', 'MasterProduct', '--product', 'DummyProduct%{ComponentSuffix}', '--as', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'MasterProduct', '-r', 'DummyProduct%{ComponentSuffix}', '-s', 'RegProduct' ],
              :ComponentName => 'RegProduct',
              :ComponentDescription => 'Dummy Product used in WEACE Regression.',
              :ComponentAuthor => 'murielsalvan@users.sourceforge.net',
              :AdditionalComponentInstall => {
                :Product => 'DummyProduct%{ComponentSuffix}',
                :Type => 'Master'
              },
              :RepositoryNormal => 'MasterServerInstalled',
              :RepositoryInstalled => 'MasterProductInstalled',
              :RepositoryConfigured => 'MasterProductConfigured',
              :CallsVarName => 'DummyProduct%{ComponentSuffix}_Calls',
              :DummyFlagVarName => 'DummyProduct%{ComponentSuffix}_DummyFlag',
              :DummyVarVarName => 'DummyProduct%{ComponentSuffix}_DummyVar',
              :AdditionalParamsVarName => 'DummyProduct%{ComponentSuffix}_AdditionalParams',
              :CheckFailErrorClass => WEACEInstall::Master::Adapters::DummyProductCheckFail::CheckError,
              :ExecFailErrorClass => WEACEInstall::Master::Adapters::DummyProductExecFail::ExecError
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
