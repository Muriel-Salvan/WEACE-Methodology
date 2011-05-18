# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Master
  
    module Adapters
  
      class CommandLine
      
        class Test_Broadcast

          include WEACE::Common

          # Check if we can install
          #
          # Return:
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
          # Return:
          # * _Exception_: An error, or nil in case of success
          def execute
            # Generate the shell script that will run WEACEExecute.
            File.open("#{@ProviderEnv[:Shell][:InternalDirectory]}/Test_Broadcast.sh", 'w') do |oFile|
              oFile << "\#!/bin/sh
#{@ProviderEnv[:WEACEExecuteCmd]} MasterServer --user Scripts_Tester --process Test_Broadcast -- --comment $1
"
            end

            return nil
          end

        end

      end

    end

  end

end
