#
# Class for bootstrapping influxdb for monasca
#
class monasca::influxdb::bootstrap(
  $influxdb_password = undef,
  $influxdb_dbuser_ro_password = undef,
  $influxdb_def_ret_pol_name = 'raw',
  $influxdb_def_ret_pol_duration = '390d',
  $influxdb_tmp_ret_pol_name = 'tmp',
  $influxdb_tmp_ret_pol_duration = '5m',
  $influxdb_retention_replication = 1,
)
{
  include monasca::params

  $influxdb_dbuser_password = $::monasca::params::api_db_password
  $script = 'bootstrap-influxdb.sh'
  $influxdb_host = 'localhost'
  $influxdb_port = 8086
  $influxdb_user = 'root'

  file { "/tmp/${script}":
    ensure  => file,
    content => template("monasca/${script}.erb"),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  Package['influxdb'] ->
  exec { "/tmp/${script}":
    subscribe   => File["/tmp/${script}"],
    path        => '/bin:/sbin:/usr/bin:/usr/sbin:/tmp',
    cwd         => '/tmp',
    user        => 'root',
    group       => 'root',
    logoutput   => true,
    refreshonly => true,
    environment => ["INFLUX_ADMIN_PASSWORD=${influxdb_password}",
                    "DB_USER_PASSWORD=${influxdb_dbuser_password}",
                    "DB_READ_ONLY_USER_PASSWORD=${influxdb_dbuser_ro_password}"],
    require     => Service['influxdb'],
  }
}
