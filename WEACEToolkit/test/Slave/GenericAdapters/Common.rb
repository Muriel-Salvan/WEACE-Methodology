#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module GenericAdapters

        module Common

          include WEACE::Test::Common

          # Give access to the plugin
          #
          # Parameters::
          # * *CodeBlock*: The code called once the plugin has been instantiated
          #   * *ioActionPlugin* (_Object_): The plugin
          def initPlugin
            initTestCase do
              require "WEACEToolkit/Slave/Adapters/#{@ProductID}/#{@ToolID}/#{@ScriptID}"
              lActionPlugin = eval("WEACE::Slave::Adapters::#{@ProductID}::#{@ToolID}::#{@ScriptID}.new")
              yield(lActionPlugin)
            end
          end

          # Ensure the signature of the plugin matches the correct one.
          def testSignature
            initPlugin do |ioActionPlugin|
              assert(ioActionPlugin.respond_to?(:execute))
              assert_equal(getExecuteArity, ioActionPlugin.method(:execute).arity)
              assert(ioActionPlugin.respond_to?(:logProduct))
              assert_equal(7, ioActionPlugin.method(:logProduct).arity)
            end
          end

          # Execute test
          #
          # Parameters::
          # * *iUserID* (_String_): User ID to use
          # * *iParameters* (<em>list<String></em>): Parameters to give the plugin
          def execTest(iUserID, iParameters)
            initPlugin do |ioActionPlugin|
              # Prepare for execution
              prepareExecution(iUserID, *iParameters) do
                # Set configurations
                lProductConfig = {}
                if (defined?(getProductConfig))
                  lProductConfig = getProductConfig
                end
                lToolConfig = {}
                if (defined?(getToolConfig))
                  lToolConfig = getToolConfig
                end
                lActionConfig = {}
                if (defined?(getActionConfig))
                  lActionConfig = getActionConfig
                end
                ioActionPlugin.instance_variable_set(:@WEACELibDir, '/path/to/WEACELib')
                @ContextVars['WEACELibDir'] = '/path/to/WEACELib'
                ioActionPlugin.instance_variable_set(:@ProductConfig, lProductConfig)
                ioActionPlugin.instance_variable_set(:@ToolConfig, lToolConfig)
                ioActionPlugin.instance_variable_set(:@ActionConfig, lActionConfig)
                # Run it
                lError = ioActionPlugin.execute(iUserID, *iParameters)
                # Check error
                assert_equal(nil, lError)
                # Check that data has been correctly set
                checkData(iUserID, *iParameters)
              end
            end
          end

        end

      end

    end

  end

end
