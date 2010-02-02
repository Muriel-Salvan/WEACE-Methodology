#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # This module is meant to be included in any test suite on MasterProcesses
        module MasterProcess

          include WEACE::Test::Install::Common

          # Execute the installation of a MasterProcess.
          #
          # Parameters:
          # * *iParameters* (<em>list<String></em>): The parameters to give to the Component's installer
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options:
          # ** *:Repository* (_String_): Name of the WEACE repository to use as a start [optional = 'MasterServerInstalled']
          # ** *:ProductRepository* (_String_): Name of the Product repository to use as a start [optional = 'Empty']
          # ** *:ContextVars* (<em>map<Symbol,Object></em>): Additional context variables to add [optional = {}]
          # ** *:CheckInstallFile* (<em>map<Symbol,String></em>): Installation file parameters to check, except :InstallationDate, :InstallationParameters, :Product and :Type [optional = {}]
          # ** *:CheckConfigFile* (<em>map<Symbol,String></em>): Configuration file parameters to check [optional = {}]
          # * *CodeBlock*: The code called to perform extra testing
          # ** *iError* (_Exception_): The error returned by the installer
          def executeInstallMasterProcess(iParameters, iOptions = {}, &iCheckCode)
            lRepository = iOptions[:Repository]
            if (lRepository == nil)
              lRepository = 'MasterServerInstalled'
            end
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
              executeInstall(
                [
                  '--install', 'MasterProcess',
                  '--process', @ToolID,
                  '--on', 'RegProduct'
                ],
                :AddRegressionMasterProviders => true,
                :Repository => lRepository,
                :ProductRepository => lProductRepository,
                :ContextVars => lContextVars,
                :CheckComponentName => "RegProduct.#{@ToolID}",
                :CheckInstallFile => lCheckInstallFile.merge(
                  {
                    :InstallationParameters => iParameters.join(' ')
                  } ),
                :CheckConfigFile => lCheckConfigFile
              ) do |iError|
                if (iCheckCode != nil)
                  iCheckCode.call(iError)
                end
              end
            end
          end

        end

      end

    end

  end

end
