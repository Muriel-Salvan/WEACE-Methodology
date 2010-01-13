#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'WEACEToolkit/Install/Slave/Adapters/Mediawiki/Install_Mediawiki_Common'

module WEACEInstall

  module Slave

    module Adapters

      module Mediawiki

        module Wiki

          class AddCommitComment

            include WEACEInstall::Slave::Adapters::Mediawiki::CommonInstall

            # Execute the installation
            #
            # Parameters:
            # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iParameters)
              installMediawikiWEACESlaveLink

              return nil
            end

          end

        end

      end

    end

  end

end
