#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Global

        # Test everything related to installing components.
        class Install < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test installing an unknown component
          def testUnknownComponent
            executeInstall(['--install', 'UnknownComponentNameForTest'], :Error => WEACEInstall::Installer::UnknownComponentError)
          end

        end

      end

    end

  end

end
