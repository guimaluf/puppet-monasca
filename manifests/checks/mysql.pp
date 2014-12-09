# == Class: monasca::checks::mysql
#
# Sets up the monasca mysql check.
#
# === Parameters
#
# [*instances*]
#   An array of instances for the check.
#   Each instance should be a hash of the check's parameters.
#   Parameters for the mysql check are:
#       server
#       user
#       port
#       pass
#       sock
#       defaults_file
#       dimensions
#       options
#   e.g.
#   $instances = [{defaults_file => '/root/.my.cnf',
#                  server => 'localhost',
#                  user => 'root'}]
#
class monasca::checks::mysql(
  $instances = [],
){
  $conf_dir = $::monasca::agent::conf_dir

  File["${conf_dir}/mysql.yaml"] ~> Service['monasca-agent']
  
  file { "${conf_dir}/mysql.yaml":
    owner   => 'root',
    group   => 'monasca-agent',
    mode    => '0640',
    content => template('monasca/checks/generic.yaml.erb'),
    require => File[$conf_dir],
  }

}