#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'A dummy Master Provider for regression purposes only.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :DummyVar,
      '-v', '--dummyvar <VariableName>', String,
      'Dummy option'
    ]
  ]
}
