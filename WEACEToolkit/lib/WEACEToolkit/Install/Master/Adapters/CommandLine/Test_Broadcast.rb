# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Master
  
    module Adapters
  
      class CommandLine
      
        class Test_Broadcast

          include WEACE::Toolbox

          # Check if we can install
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def check
            rError = nil

            if (!File.exists?(@ProductConfig[:InstallDir]))
              rError = WEACE::MissingDirError.new("Missing directory: #{@ProductConfig[:InstallDir]}")
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
            File.open("#{@ProductConfig[:InstallDir]}/Test_Broadcast.sh", 'w') do |oFile|
              oFile << "\#!/usr/bin/env ruby
#{@ProviderEnv[:WEACEExecuteCmd]} MasterServer Scripts_Tester Test_Broadcast
"
            end

            return nil
          end

        end

      end

    end

  end

end
