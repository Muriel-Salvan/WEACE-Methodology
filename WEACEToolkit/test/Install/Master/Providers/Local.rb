#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Providers

          class Local < ::Test::Unit::TestCase

            include WEACE::Test::Install::Providers

            # Check the environment returned by the plugin.
            # Use normal assertions to check it.
            #
            # Parameters:
            # * *iProviderEnv* (<em>map<Symbol,Object></em>): The Provider environment to check.
            def checkEnvironment(iProviderEnv)
              assert_equal({}, iProviderEnv)
            end

          end

        end

      end

    end

  end

end
