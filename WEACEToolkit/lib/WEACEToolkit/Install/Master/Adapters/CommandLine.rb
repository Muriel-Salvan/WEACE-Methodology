#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class CommandLine

        include WEACE::Common

        # Check if we can install
        #
        # Return::
        # * _Exception_: An error, or nil in case of success
        def check
          rError = nil

          if (@ProviderEnv[:Shell] == nil)
            rError = RuntimeError.new('This Provider does not accept Shell directories.')
          elsif (!File.exists?(@ProviderEnv[:Shell][:InternalDirectory]))
            rError = WEACE::MissingDirError.new("Missing directory: #{@ProviderEnv[:Shell][:InternalDirectory]}")
          end

          return rError
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return::
        # * _Exception_: An error, or nil in case of success
        def execute
          return nil
        end

      end

    end

  end

end
