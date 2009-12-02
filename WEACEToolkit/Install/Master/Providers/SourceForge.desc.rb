#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'The SourceForge.net environment specifics for WEACE Master Server/Adapters.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :ProjectUnixName,
      '-p', '--project <ProjectUnixName>', String,
      '<ProjectUnixName>: SourceForge.net\'s project name.',
      'Example: myproject'
    ]
  ]
}
