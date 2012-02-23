#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
#   * :Title (_String_): Name of the plugin
#   * :Description (_String_): Quick description
#   * :VarOptions (<em>list< [Symbol,list<Object>] ></em>): List of variables bound to parameters on command line options
{
  :Description => 'Product Redmine adapted to WEACE Master.',
  :Author => 'muriel@x-aeon.com',
  :VarOptions => [
    [
      :RedmineDir,
      '-d', '--redminedir <RedmineDir>', String,
      '<RedmineDir>: Redmine\'s installation directory.',
      'Example: /home/groups/m/my/myproject/redmine'
    ]
  ],
  :OptionsExample => '--redminedir /home/redmine'
}
