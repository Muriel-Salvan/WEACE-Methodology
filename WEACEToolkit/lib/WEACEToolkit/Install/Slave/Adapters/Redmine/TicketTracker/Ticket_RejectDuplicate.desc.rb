#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'This adapter creates a relation between a master and a slave tickets, and reject the slave as a duplicate of the master.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :RedmineDir,
      '-d', '--redminedir <RedmineDir>', String,
      '<RedmineDir>: Redmine\'s installation directory.',
      'Example: /home/groups/m/my/myproject/redmine'
    ],
    [
      :RubyGemsLibDir,
      '-r', '--rubygemslib <RubyGemsPath>', String,
      '<RubyGemsPath>: Path to the directory containing rubygems.rb.',
      'Example: /home/groups/m/my/myproject/rubygems/lib'
    ],
    [
      :GemsDir,
      '-g', '--gems <GemsPath>', String,
      '<GemsPath>: Path to the directory containing the Gems repository.',
      'Example: /home/groups/m/my/myproject/rubygems/mygems'
    ],
    [
      :MySQLLibDir,
      '-m', '--mysql <MySQLLibPath>', String,
      '<MySQLLibPath>: Path to the directory containing the MySQL (C-Connector) library.',
      'Example: /home/groups/m/my/myproject/mysql/lib'
    ]
  ]
}
