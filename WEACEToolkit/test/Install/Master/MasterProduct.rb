#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # This module is meant to be included in any test suite on MasterProducts
        module MasterProduct

          include WEACE::Test::Install::Common

          # Execute the installation of a MasterProduct.
          #
          # Parameters:
          # * *iParameters* (<em>list<String></em>): The parameters to give to the Component's installer
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options:
          # ** *:Error* (_Exception_): Expected error from the Installer [optional = nil]
          # ** *:ProductRepository* (_String_): Name of the Product repository to use as a start [optional = 'Empty']
          # ** *:ContextVars* (<em>map<Symbol,Object></em>): Additional context variables to add [optional = {}]
          # ** *:CheckInstallFile* (<em>map<Symbol,String></em>): Installation file parameters to check, except :InstallationDate, :InstallationParameters, :Product and :Type [optional = {}]
          # ** *:CheckConfigFile* (<em>map<Symbol,String></em>): Configuration file parameters to check [optional = {}]
          # * *CodeBlock*: The code called to perform extra testing
          # ** *iError* (_Exception_): The error returned by the installer
          def executeInstallMasterProduct(iParameters, iOptions = {}, &iCheckCode)
            lExpectedError = iOptions[:Error]
            lProductRepository = iOptions[:ProductRepository]
            if (lProductRepository == nil)
              lProductRepository = 'Empty'
            end
            lContextVars = iOptions[:ContextVars]
            if (lContextVars == nil)
              lContextVars = {}
            end
            lCheckInstallFile = iOptions[:CheckInstallFile]
            if (lCheckInstallFile == nil)
              lCheckInstallFile = {}
            end
            lCheckConfigFile = iOptions[:CheckConfigFile]
            if (lCheckConfigFile == nil)
              lCheckConfigFile = {}
            end

            initTestCase do
              lCheckSuccessAttributes = {}
              if (lCheckInstallFile != nil)
                lCheckSuccessAttributes[:CheckInstallFile] = lCheckInstallFile.merge(
                  {
                    :InstallationParameters => iParameters.join(' '),
                    :Product => @ProductID,
                    :Type => 'Master'
                  } )
              end
              if (lCheckConfigFile != nil)
                lCheckSuccessAttributes[:CheckConfigFile] = lCheckConfigFile
              end
              if (lExpectedError == nil)
                lCheckSuccessAttributes[:CheckComponentName] = 'RegProduct'
              end
              executeInstall(
                [
                  '--install', 'MasterProduct',
                  '--product', @ProductID,
                  '--as', 'RegProduct',
                  '--'
                ] + iParameters,
                lCheckSuccessAttributes.merge( {
                  :AddRegressionMasterProviders => true,
                  :Repository => 'Dummy/MasterServerInstalled',
                  :ProductRepository => lProductRepository,
                  :ContextVars => lContextVars,
                  :Error => lExpectedError
                } )
              ) do |iError|
                if (iCheckCode != nil)
                  iCheckCode.call(iError)
                end
              end
            end
          end

          # Initialize a test case for a generic Component
          #
          # Parameters:
          # * *CodeBlock*: The code to call once it is initialized
          def initMasterProductTest
            initTestCase do
              # Get test suite specificities
              @Specs = replaceObjectVars(getMasterProductTestSpecs)
              yield
            end
          end

          # Test a normal run
          def testNormal
            initMasterProductTest do
              executeInstallMasterProduct(@Specs[:InstallComponentParameters],
                :ProductRepository => @Specs[:ProductRepositoryVirgin],
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckInstallFile => @Specs[:ComponentInstallInfo],
                :CheckConfigFile => @Specs[:ComponentConfigInfo]
              ) do |iError|
                compareWithRepository(@Specs[:ProductRepositoryInstalled])
              end
            end
          end

          # Test a normal run (short version)
          def testNormalShort
            initMasterProductTest do
              executeInstallMasterProduct(@Specs[:InstallComponentParametersShort],
                :ProductRepository => @Specs[:ProductRepositoryVirgin],
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckInstallFile => @Specs[:ComponentInstallInfo],
                :CheckConfigFile => @Specs[:ComponentConfigInfo]
              ) do |iError|
                compareWithRepository(@Specs[:ProductRepositoryInstalled])
              end
            end
          end

          # Test a duplicate run with a corrupted installation info.
          # The Product has already the info, but the Component is not marked as installed.
          def testDuplicate
            initMasterProductTest do
              executeInstallMasterProduct(@Specs[:InstallComponentParameters],
                :ProductRepository => @Specs[:ProductRepositoryInstalled],
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckInstallFile => @Specs[:ComponentInstallInfo],
                :CheckConfigFile => @Specs[:ComponentConfigInfo]
              ) do |iError|
                compareWithRepository(@Specs[:ProductRepositoryInstalled])
              end
            end
          end

          # Test that checks return an error if the Product is not valid.
          def testCheckInvalid
            initMasterProductTest do
              if (@Specs[:ProductRepositoryInvalid] != nil)
                executeInstallMasterProduct(@Specs[:InstallComponentParameters],
                  :ProductRepository => @Specs[:ProductRepositoryInvalid],
                  :ContextVars => {
                    'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                  },
                  :Error => WEACEInstall::Installer::CheckError
                ) do |iError|
                  compareWithRepository(@Specs[:ProductRepositoryInvalid])
                  assert(iError.CheckError.is_a?(@Specs[:CheckErrorClass]))
                end
              end
            end
          end

        end

      end

    end

  end

end
