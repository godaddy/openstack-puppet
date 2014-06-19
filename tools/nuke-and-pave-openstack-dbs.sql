drop database if exists glance;
drop database if exists heat;
drop database if exists keystone;
drop database if exists neutron;
drop database if exists nova;

create database glance;
create database heat;
create database keystone;
create database neutron;
create database nova;

grant all on glance.* to 'glance'@'%' identified by 'glance';
grant all on heat.* to 'heat'@'%' identified by 'heat';
grant all on keystone.* to 'keystone'@'%' identified by 'keystone';
grant all on neutron.* to 'neutron'@'%' identified by 'neutron';
grant all on nova.* to 'nova'@'%' identified by 'nova';

