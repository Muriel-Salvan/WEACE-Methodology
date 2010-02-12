# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master
  
    class Server

      module Processes

        class Test_Broadcast

          include WEACE::Common

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters:
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return:
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            checkVar(:Comment, 'Comment to send with the Ping')

            ioSlaveActions.addSlaveAction(
              Tools::All, Actions::Test_Ping,
              @Comment
            )

            return nil
          end

          # Get the command line options for this Process
          #
          # Return:
          # * _OptionParser_: The corresponding options
          def getOptions
            rOptions = OptionParser.new

            rOptions.banner = '-c|--comment <Comment>'
            rOptions.on('-c', '--comment <Comment>', String,
              '<Comment>: Comment to send with th Ping.') do |iArg|
              @Comment = iArg
            end

            return rOptions
          end

        end

      end
    
    end

  end

end
