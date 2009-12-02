#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'This adapter is triggered when a Ticket is marked as duplicating another one.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :RedmineDir,
      '-d', '--redminedir <RedmineDir>', String,
      '<RedmineDir>: Redmine\'s installation directory.',
      'Example: /home/groups/m/my/myproject/redmine'
    ],
    [
      :RubyPath,
      '-r', '--ruby <RubyPath>', String,
      '<RubyPath>: Ruby\'s path.',
      'Example: /usr/bin/ruby'
    ]
  ]
}
