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
    if ($Context[:OS_ExecAnswers].empty?)
      $Variables[:OS_Exec] << [ 'error', "ERROR: Execution of command \"#{iCommand}\" is not prepared by WEACE Regression." ]
    else
      rResult = $Context[:OS_ExecAnswers][0]
      $Context[:OS_ExecAnswers].delete_at(0)
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

            # Get the Product's configuration to give the plugin for testing
            #
            # Return:
            # * <em>map<Symbol,Object></em>: The Product configuration
            def getProductConfig
              return {
                :MediawikiDir => '/path/to/Mediawiki'
              }
            end

          end

        end

      end

    end

  end

end
