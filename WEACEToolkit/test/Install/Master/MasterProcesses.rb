#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Processes.
        # Don't test each Master Product here. Just the generic functionalities with Dummy MasterProcesses.
        class MasterProcesses < ::Test::Unit::TestCase

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
    class DummyProduct
      class DummyProcessCheckFail
        class CheckError < RuntimeError
        end
      end
      class DummyProcessExecFail
        class ExecError < RuntimeError
        end
      end
    end
  end
end
"
              )
            return {
              :InstallParameters => [ '--install', 'MasterProcess', '--process', 'DummyProcess%{ComponentSuffix}', '--on', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'MasterProcess', '-c', 'DummyProcess%{ComponentSuffix}', '-o', 'RegProduct' ],
              :ComponentName => 'RegProduct.DummyProcess%{ComponentSuffix}',
              :ComponentDescription => 'This Process is used for WEACE Regression only.',
              :ComponentAuthor => 'murielsalvan@users.sourceforge.net',
              :AdditionalComponentInstall => {},
              :RepositoryNormal => 'MasterProductInstalled',
              :RepositoryInstalled => 'MasterProcessInstalled',
              :RepositoryConfigured => 'MasterProcessConfigured',
              :CallsVarName => 'DummyProduct_DummyProcess%{ComponentSuffix}_Calls',
              :DummyFlagVarName => 'DummyProduct_DummyProcess%{ComponentSuffix}_DummyFlag',
              :DummyVarVarName => 'DummyProduct_DummyProcess%{ComponentSuffix}_DummyVar',
              :AdditionalParamsVarName => 'DummyProduct_DummyProcess%{ComponentSuffix}_AdditionalParams',
              :CheckFailErrorClass => WEACEInstall::Master::Adapters::DummyProduct::DummyProcessCheckFail::CheckError,
              :ExecFailErrorClass => WEACEInstall::Master::Adapters::DummyProduct::DummyProcessExecFail::ExecError
            }
          end

          # Test installing a Master Process without the Master Product
          def testMasterProcessWithoutMasterProduct
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :Error => WEACEInstall::Installer::MissingMasterProductError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process option
          def testMasterProcessWithoutProcess
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process argument
          def testMasterProcessWithoutProcessArg
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct', '--process'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on option
          def testMasterProcessWithoutOn
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on argument
          def testMasterProcessWithoutOnArg
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

        end

      end

    end

  end

end
