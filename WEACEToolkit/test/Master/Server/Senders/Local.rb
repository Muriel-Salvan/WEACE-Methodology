#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Senders

        class Local < ::Test::Unit::TestCase

          include WEACE::Test::Master::MasterSender

          # Give additional execution parameters to be given to executeSender method
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The additional parameters
          def getExecutionParameters
            return {
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyAction' ],
                [ 'DummyProduct', 'DummyTool', 'DummyActionWithParams' ],
                [ 'DummyProduct', 'DummyTool2', 'DummyAction2' ]
              ],
              :ClientConfigureProducts => [
                [
                  'DummyProduct', 'DummyTool',
                  {}
                ],
                [
                  'DummyProduct', 'DummyTool2',
                  {}
                ]
              ]
            }
          end

          # Prepare for execution.
          # Use this method to bypass methods to better track WEACE behaviour.
          #
          # Parameters:
          # * *CodeBlock*: The code to call once preparation is done
          def prepareExecution
            yield
          end

          # Get back the User ID and the Actions once sent.
          # This method is also used to assert some specific parts of the execution.
          #
          # Return:
          # * _String_: The User ID
          # * <em>map<String,map<String,list<list<String>>>></em>: The Actions
          def getUserActions
            assert($Variables[:SlaveActions] != nil)

            return $Variables[:SlaveActions][:UserID], $Variables[:SlaveActions][:ActionsToExecute]
          end

        end

      end

    end

  end

end
