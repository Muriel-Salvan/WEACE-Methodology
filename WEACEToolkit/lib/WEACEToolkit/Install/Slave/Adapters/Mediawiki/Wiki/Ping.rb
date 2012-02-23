#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Adapters

      class Mediawiki

        class Wiki

          class Ping

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

  end

end
