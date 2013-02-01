====================
miniascape
====================

Disclaimer
-----------------

WARNING: miniascape is in pre-alpha state and will heavily udpate day by day,
so it may not work in your environment or might cause trouble. TRY IT IN YOUR
OWN RISK, PLEASE.


About
----------------

Miniascape is a template compiler optimized for specific purpose to generate
collection of configuration files for virt. host, script to build VMs, and misc
data for VMs, to setup libvirt based virtualization environment (virtualization
'miniascape') to build VMs quickly and easily.

Main objects are

* Setup network configuration including DHCP and DNS for VMs much easier.

* Lightweight; Does not require expensive high-performance servers.
  
  I try to make it working on my non-high power vaio note pc having Intel Atom
  CPU and only 2G RAM.

* Fully utilize exsiting library, tools and do not intend to replace or
  reinvent wheels.

* Do not bring yet-another runtime dependency other than existing ones
  like libvirt and virt-install and miniascape trys to generate scripts
  utilizing these and runnable standalone.


And non-goals are:

* Intend to become a replacement for other feature rich software such like
  RHEV, RHN Satellite and cobbler, CloudForms/SystemEngine, etc.

* Provides a UI (GUI, Web UI) to manage lifecycle of VMs at ease.


Usage
====================

1. Setup host: mount iso images and setup kickstart installation trees, etc.
2. Arrange configuration files to override default configs provided in /etc/miniascape/conf.d/default/;

   e.g. /etc/miniascape/conf.d/default/common/31_virtinst.yml to override
   virtinst.location (URL of ks tree)

3. Run miniascape to generate libvirt network xml, auto installation script and
   vm build scripts:

   miniascape ge [Options ...]

   or 

   miniascape generate [Options ...]

4. Run built script in the working dir (<workdir>/guests.d/<guest_name>/vmbuild.sh)
   on target libvirt host


How it works?
====================

Miniascape is just a template compiler optimized to generate ks.cfg, wrapper
scripts around virt-install and configurations installed into the libvirt host
in current implementation.

* Inputs: multiple YAML configuration files and template files
* Outputs: libvirt network XML, kickstart files and VM build scripts, etc.
* Template engine used: Jinja2: http://jinja.pocoo.org


Configurations
---------------------

Configurations and parameters are in YAML configuration files (default:
/etc/miniascape/conf.d/**/*.yml).

* Meta: conf.d/META/*.yml: Define config file dirs and loading orders

* Common: common/*.yml 

* Host global:

  * host.d/*.yml
  * networks.d/*.yml: Libvirt network parameters
  * storages.d/*.yml: Libvirt storage pool parameters (not used in actual)

* VM (guest) specific:

  1. sysgroups.d/<guest kind>: Parameters common in system groups
  2. guests.d/<guest name>: Guest specific parameters

Configuration files are loaded in the above order and possible to customize by
putting your configuration files.


Templates
--------------------

I chose jinja2 as template engine for miniascape.

Miniascape contains some concrete template examples under
/usr/share/miniascape/templates:

* autoinstall.d/: Auto installation configuration files (kickstart) templates
* host/: Templates for host like network xml, wrapper script for virt-install


Prerequisites
====================

Hardware and base OS
----------------------

* Intel x86 (i386 or x86_64) machine with VT extension (Intel VT or AMD-V) enabled
* RHEL 6 or Fedora 13+ or any linux distributions corresponding to these versions


Tools and libs
-------------------

 * python-jinja2-cui: https://github.com/ssato/python-jinja2-cui
 * libvirt and its python binding
 * python-virtinst
 * qemu-kvm
 * nginx or (apache) httpd [option]
 * etc.


Build
====================

Run `python setup.py srpm` and mock dist/SRPMS/<built-srpm>, or 
run `python setup.py rpm`.


Installation
====================

* [Recommended] build srpm, rpm w/ mock and install it
* build and install: `python setup.py build` and `python setup.py install`


TODO
=====================

Upstream works
-------------------

* --config (or --profile?) file option for virt-install [Should]
* more D-Bus APIs for dnsmasq to simplify the control process of dnsmasq and
  make it dynamic [May]


Done:

* python-virtinst (virt-install) fixes and enhancements:

  * perms=rw storage option is not handled correctly: my patch was merged.
  * Fix a bug that multiple storage volume cannot be created in a same storage
    pool with virt-install --disk option (rhbz#857424): My patch was merged.

* libvirt fixes and enhancements:

  * Implemented dnsmasq backend for libvirt: My patch was merged.


miniascape itself
-----------------------

* Utilize python-anyconfig: WIP; Started to working on enhancements in it to
  work w/ miniascape

* site-designer: tool or sub command to generate config files from default or
  user-defined parameters and config templates

* Some more guest configurations and templates
* Write unit tests for template files including snippets
* Added some more host-configuration stuff, like autofs, www (apache or nginx),
  nfs, iscsi, pxe boot, etc.
* Documents

Done:

* control or meta config file which controls which config files to be loaded:
  Done. see miniascape/config.py


License
====================

This is distributed under GPLv3 or later.


Author
=======================

Satoru SATOH <ssato at redhat.com>



EXAMPLE Session
=========================

::

  ssato@localhost% miniascape
  Usage: /usr/bin/miniascape COMMAND_OR_COMMAND_ABBREV [Options] [Arg ...]

  Commands: init, generate, guest, net
  Command abbreviations: i, ge, gu, n

  ssato@localhost% miniascape n -f
  Are you sure to generate networks in workdir-20120921 ? [y/n]: y
  [INFO] Loading cds-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading cds-2's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-5-client-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-5-cluster-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-5-cluster-2's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-6-client-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-6-client-2's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-6-cluster-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhel-6-cluster-2's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhs-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhs-2's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhs-3's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhs-4's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhua's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhui-rhel-5-client-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading rhui-rhel-6-client-1's config from /etc/miniascape/conf.d/default
  [INFO] Loading sam's config from /etc/miniascape/conf.d/default
  [INFO] Loading satellite's config from /etc/miniascape/conf.d/default
  ssato@localhost% ls workdir-20120921/host/networks.d
  service.xml  service.yml
  ssato@localhost% cat workdir-20120921/host/networks.d/service.xml
  <network>
    <name>service</name>
    <forward mode='nat'/>
    <bridge name='virbr5' stp='on' delay='0' />
    <domain name='m2.local'/>
    <dns>
      <!-- Libvirt host aliases: -->
      <host ip='192.168.155.254'><hostname>gw.m2.local</hostname></host>
      <host ip='192.168.155.254'><hostname>ks.m2.local</hostname></host>
      <!-- TODO: Parameterize the followings and get from config files -->
      <host ip='192.168.155.100'><hostname>rhel-5-cluster.m2.local</hostname></host>
      <host ip='192.168.155.110'><hostname>rhel-6-cluster.m2.local</hostname></host>
      <host ip='192.168.155.10'><hostname>satellite.m2.local</hostname></host>
      <host ip='192.168.155.15'><hostname>sam.m2.local</hostname></host>
      <host ip='192.168.155.20'><hostname>rhua.m2.local</hostname></host>
      <host ip='192.168.155.21'><hostname>cds-1.m2.local</hostname></host>
      <host ip='192.168.155.22'><hostname>cds-2.m2.local</hostname></host>
      <host ip='192.168.155.51'><hostname>rhs-1.m2.local</hostname></host>
      <host ip='192.168.155.52'><hostname>rhs-2.m2.local</hostname></host>
      <host ip='192.168.155.53'><hostname>rhs-3.m2.local</hostname></host>
      <host ip='192.168.155.54'><hostname>rhs-4.m2.local</hostname></host>
      <host ip='192.168.155.101'><hostname>rhel-5-cluster-1.m2.local</hostname></host>
      <host ip='192.168.155.102'><hostname>rhel-5-cluster-2.m2.local</hostname></host>
      <host ip='192.168.155.111'><hostname>rhel-6-cluster-1.m2.local</hostname></host>
      <host ip='192.168.155.112'><hostname>rhel-6-cluster-2.m2.local</hostname></host>
      <host ip='192.158.155.151'><hostname>rhel-5-client-1.m2.local</hostname></host>
      <host ip='192.168.155.161'><hostname>rhel-6-client-1.m2.local</hostname></host>
      <host ip='192.168.155.162'><hostname>rhel-6-client-2.m2.local</hostname></host>
    </dns>
    <ip address='192.168.155.254' netmask='255.255.255.0'>
      <dhcp>
        <range start='192.168.155.200' end='192.168.155.250'/>
        <host mac='52:54:00:05:00:10' name='satellite.m2.local' ip='192.168.155.10'/>
        <host mac='52:54:00:05:00:15' name='sam.m2.local' ip='192.168.155.15'/>
        <host mac='52:54:00:05:00:20' name='rhua.m2.local' ip='192.168.155.20'/>
        <host mac='52:54:00:05:00:21' name='cds-1.m2.local' ip='192.168.155.21'/>
        <host mac='52:54:00:05:00:22' name='cds-2.m2.local' ip='192.168.155.22'/>
        <host mac='52:54:00:05:00:51' name='rhs-1.m2.local' ip='192.168.155.51'/>
        <host mac='52:54:00:05:00:52' name='rhs-2.m2.local' ip='192.168.155.52'/>
        <host mac='52:54:00:05:00:53' name='rhs-3.m2.local' ip='192.168.155.53'/>
        <host mac='52:54:00:05:00:54' name='rhs-4.m2.local' ip='192.168.155.54'/>
        <host mac='52:54:00:05:01:01' name='rhel-5-cluster-1.m2.local' ip='192.168.155.101'/>
        <host mac='52:54:00:05:01:02' name='rhel-5-cluster-2.m2.local' ip='192.168.155.102'/>
        <host mac='52:54:00:05:01:11' name='rhel-6-cluster-1.m2.local' ip='192.168.155.111'/>
        <host mac='52:54:00:05:01:12' name='rhel-6-cluster-2.m2.local' ip='192.168.155.112'/>
        <host mac='52:54:00:05:01:51' name='rhel-5-client-1.m2.local' ip='192.158.155.151'/>
        <host mac='52:54:00:05:01:61' name='rhel-6-client-1.m2.local' ip='192.168.155.161'/>
        <host mac='52:54:00:05:01:62' name='rhel-6-client-2.m2.local' ip='192.168.155.162'/>
      </dhcp>
    </ip>
  </network>
  ssato@localhost% sudo virsh net-define workdir-20120921/host/networks.d/service.xml
  [sudo] password for ssato:
  ...
  ssato@localhost% sudo virsh net-start service
  ...
  ssato@localhost% sudo virsh net-autostart service
  ...
  ssato@localhost% miniascape gu -h
  Usage: miniascape [OPTION ...] [NAME]

  Options:
    -h, --help            show this help message and exit
    -t TMPLDIR, --tmpldir=TMPLDIR
                          Template top dir[s]
                          [[/usr/share/miniascape/templates]]
    -c CONFDIR, --confdir=CONFDIR
                          Configurations (context files) top dir
                          [/etc/miniascape/conf.d/default]
    -w WORKDIR, --workdir=WORKDIR
                          Working dir to dump results
                          [workdir-20120921/guests.d/<NAME>]
    -A, --genall          Generate configs for all guests
    -D, --debug           Debug mode
  ssato@localhost% miniascape gu
  Usage: miniascape [OPTION ...] [NAME]

  Options:
    -h, --help            show this help message and exit
    -t TMPLDIR, --tmpldir=TMPLDIR
                          Template top dir[s]
                          [[/usr/share/miniascape/templates]]
    -c CONFDIR, --confdir=CONFDIR
                          Configurations (context files) top dir
                          [/etc/miniascape/conf.d/default]
    -w WORKDIR, --workdir=WORKDIR
                          Working dir to dump results
                          [workdir-20120921/guests.d/<NAME>]
    -A, --genall          Generate configs for all guests
    -D, --debug           Debug mode

  Available VMs: cds-1, cds-2, rhel-5-client-1, rhel-5-cluster-1,
  rhel-5-cluster-2, rhel-6-client-1, rhel-6-client-2, rhel-6-cluster-1,
  rhel-6-cluster-2, rhs-1, rhs-2, rhs-3, rhs-4, rhua, rhui-rhel-5-client-1,
  rhui-rhel-6-client-1, sam, satellite
  ssato@localhost% miniascape gu sam -w workdir-20120921/guests.d/sam
  [INFO] Generating setup data archive to embedded: sam
  [INFO] Generating workdir-20120921/guests.d/sam/ks.cfg from sam-ks.cfg [autoinst]
  [INFO] Generating workdir-20120921/guests.d/sam/vmbuild.sh from vmbuild.sh [virtinst]
  ssato@localhost% sudo bash -x ./workdir-20120921/guests.d/sam/vmbuild.sh
  + set -ex
  + test 0 -gt 0
  + ks_path=./workdir-20120921/guests.d/sam/ks.cfg
  + kscfg=ks.cfg
  + location=http://ks.m2.local/contents/RHEL/6/3/x86_64/default/
  + virt-install --check-cpu --hvm --accelerate --noreboot --noautoconsole --name=sam --connect=qemu:///system --wait=20 --ram=2048 --arch=x86_64 --vcpus=2 --graphics vnc --os-type=linux --os-variant=rhel6 --location=http://ks.m2.local/contents/RHEL/6/3/x86_64/default/ --initrd-inject=./workdir-20120921/guests.d/sam/ks.cfg --disk pool=default,format=qcow2,cache=none,size=5 --network network=service,model=virtio,mac=52:54:00:05:00:15 '--extra-args=ks=file:/ks.cfg ksdevice=eth0 '

  Starting install...
  Retrieving file vmlinuz...                                    | 7.6 MB     00:00 !!!
  Retrieving file initrd.img...                                 |  58 MB     00:00 !!!
  Allocating 'sam-2.img'                                        | 5.0 GB     00:00
  Creating domain...                                            |    0 B     00:00
  Domain installation still in progress. Waiting 20 minutes for installation to complete.
  ssato@localhost%


.. vim:sw=2:ts=2:et: