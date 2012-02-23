#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      # this module is meant to be required by any individual Component's test suite.
      module IndividualComponent

        include WEACE::Test::Install::Common

        # Execute the installation of an individual Component.
        #
        # Parameters::
        # * *iParameters* (<em>list<String></em>): The parameters to give to the Component's installer
        # * *iComponentParameters* (<em>list<String></em>): The parameters to give to the Component's installer, specific to the Component
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options:
        #   * *:Error* (_Exception_): Expected error from the Installer [optional = nil]
        #   * *:ProductRepository* (_String_): Name of the Product repository to use as a start [optional = 'Empty']
        #   * *:CheckInstallFile* (<em>map<Symbol,String></em>): Installation file parameters to check, except :InstallationDate and :InstallationParameters [optional = {}]
        #   * *:CheckConfigFile* (<em>map<Symbol,String></em>): Configuration file parameters to check [optional = {}]
        # * *CodeBlock*: The code called to perform extra testing
        #   * *iError* (_Exception_): The error returned by the installer
        def executeInstallIndividualComponent(iParameters, iComponentParameters, iOptions = {}, &iCheckCode)
          lExpectedError = iOptions[:Error]
          lProductRepository = iOptions[:ProductRepository]
          if (lProductRepository == nil)
            lProductRepository = 'Empty'
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
                  :InstallationParameters => iComponentParameters.join(' '),
                } )
            end
            if (lCheckConfigFile != nil)
              lCheckSuccessAttributes[:CheckConfigFile] = lCheckConfigFile
            end
            if (lExpectedError == nil)
              lCheckSuccessAttributes[:CheckComponentName] = @Specs[:ComponentName]
            end
            lRegProvidersVarName = nil
            if (@Type == 'Master')
              lRegProvidersVarName = :AddRegressionMasterProviders
            else
              lRegProvidersVarName = :AddRegressionSlaveProviders
            end
            executeInstall(iParameters + [ '--' ] + iComponentParameters,
              lCheckSuccessAttributes.merge( {
                lRegProvidersVarName => true,
                :Repository => @Specs[:Repository],
                :ProductRepository => lProductRepository,
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net',
                  'WEACESlaveInfoURL' => 'http://weacemethod.sourceforge.net',
                  'WEACEExecuteCmd' => '/usr/bin/ruby -w WEACEExecute.rb'
                },
                :Error => lExpectedError
              } )
            ) do |iError|
              if (iCheckCode != nil)
                iCheckCode.call(iError)
              end
            end
          end
        end

        # Initialize a test case for an individual Component
        #
        # Parameters::
        # * *CodeBlock*: The code to call once it is initialized
        def initIndividualComponentTest
          initTestCase do
            # Get test suite specificities
            @Specs = replaceObjectVars(getIndividualComponentTestSpecs)
            yield
          end
        end

        # Test a normal run
        def testNormal
          initIndividualComponentTest do
            executeInstallIndividualComponent(@Specs[:InstallParameters], @Specs[:InstallComponentParameters],
              :ProductRepository => @Specs[:ProductRepositoryVirgin],
              :CheckInstallFile => @Specs[:ComponentInstallInfo],
              :CheckConfigFile => @Specs[:ComponentConfigInfo]
            ) do |iError|
              compareWithRepository(@Specs[:ProductRepositoryInstalled])
            end
          end
        end

        # Test a normal run (short version)
        def testNormalShort
          initIndividualComponentTest do
            executeInstallIndividualComponent(@Specs[:InstallParametersShort], @Specs[:InstallComponentParametersShort],
              :ProductRepository => @Specs[:ProductRepositoryVirgin],
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
          initIndividualComponentTest do
            executeInstallIndividualComponent(@Specs[:InstallParameters], @Specs[:InstallComponentParameters],
              :ProductRepository => @Specs[:ProductRepositoryInstalled],
              :CheckInstallFile => @Specs[:ComponentInstallInfo],
              :CheckConfigFile => @Specs[:ComponentConfigInfo]
            ) do |iError|
              compareWithRepository(@Specs[:ProductRepositoryInstalled])
            end
          end
        end

        # Test that checks return an error if the Product is not valid.
        def testCheckInvalid
          initIndividualComponentTest do
            if (@Specs[:ProductRepositoryInvalid] != nil)
              executeInstallIndividualComponent(@Specs[:InstallParameters], @Specs[:InstallComponentParameters],
                :ProductRepository => @Specs[:ProductRepositoryInvalid],
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
