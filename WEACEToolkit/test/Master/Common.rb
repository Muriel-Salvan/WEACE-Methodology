#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Common

        # Execute WEACE Master Server
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Master Server
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # Return:
        # * _Exception_: Error returned by the Installer's execution
        def executeMaster(iParameters, iOptions = {})
          # Parse options
          lExpectedErrorClass = iOptions[:Error]

          require 'bin/WEACEExecute'
          rError = WEACE::execute( [ 'MasterServer' ] + iParameters )

          # Check
          if (lExpectedErrorClass == nil)
            assert_equal(nil, rError)
          else
            assert(rError.kind_of?(lExpectedErrorClass))
          end

          return rError
        end

      end

    end

  end

end
