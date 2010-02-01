#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'Dummy Product used in WEACE Regression.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :DummyVar,
      '-v', '--dummyvar <VariableName>', String,
      'Dummy option'
    ]
  ]
}
