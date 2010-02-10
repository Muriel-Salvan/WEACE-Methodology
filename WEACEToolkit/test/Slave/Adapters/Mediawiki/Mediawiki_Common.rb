#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Methods used in Mediawiki testing

module Kernel

  # Execute a command on the OS.
  #
  # Parameters:
  # * *iCommand* (_String_): The command to execute
  # Return:
  # * _String_: The result
  def backquote_regression(iCommand)
    rResult = ''

    # Record the query
    if ($Variables[:OS_Exec] == nil)
      $Variables[:OS_Exec] = []
    end
    $Variables[:OS_Exec] << [ 'query', iCommand ]

    # Send an automated answer
    if ($WEACERegression_ExecAnswers.empty?)
      $Variables[:OS_Exec] << [ 'error', "ERROR: Execution of command \"#{iCommand}\" is not prepared by WEACE Regression." ]
    else
      rResult = $WEACERegression_ExecAnswers[0]
      $WEACERegression_ExecAnswers.delete_at(0)
    end

    return rResult
  end

end

module WEACE

  module Test

    module Slave

      module Adapters

        module Mediawiki

          module Common

            # Execute a test for Mediawiki Slave Adapters
            #
            # Parameters:
            # * *iProductConfig* (<em>map<Symbol,Object></em>): The Product configuration
            # * *iParameters* (<em>list<String></em>): Parameters given to the Adapter
            # * *iOptions* (<em>map<Symbol,Object></em>): Options [optional = {}]
            # ** *:OSExecAnswers* (<em>list<String></em>): List of answers calls to `` have to return [optional = []]
            # * *CodeBlock*: The code called once the Adapter has been executed [optional = nil]:
            # ** *iError* (_Exception_): Error returned by the Adapter.
            def executeSlaveAdapterMediawiki(iProductConfig, iParameters, iOptions = {}, &iCodeCheck)
              # Parse options
              lOSExecAnswers = iOptions[:OSExecAnswers]
              if (lOSExecAnswers == nil)
                lOSExecAnswers = []
              end

              # Catch `` executions
              WEACE::Test::Common::changeMethod(
                Kernel,
                :`,
                :backquote_regression,
                true
              ) do
                $WEACERegression_ExecAnswers = lOSExecAnswers
                executeSlaveAdapter(
                  iProductConfig,
                  iParameters
                ) do |iError|
                  if (iCodeCheck != nil)
                    iCodeCheck.call(iError)
                  end
                end
              end
            end

          end

        end

      end

    end

  end

end
