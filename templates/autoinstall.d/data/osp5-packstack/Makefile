# Makefile to install and setup OpenStack (RDO).
# 
# see also:
# * http://openstack.redhat.com/Neutron-Quickstart
# * http://openstack.redhat.com/Running_an_instance_with_Neutron
# 
WORKDIR ?= /root/setup
FULL_UPDATE ?= no

#
# Required software channels:
#
#   * RDO:
#     - RHEL 6 x86_64 Optional
#
#   * Red Hat OpenStack (supported version):
#     - RHEL 6 x86_64 Optional
#     - Red Hat OpenStack 3.0 (rhel-x86_64-server-6-ost-3) (Havana not in RHOS yet)
#
RHN_AKEYS ?= {{ rhn.activationkeys|default('') }}
RHN_PROFILENAME ?= {% if rhn.profilename is defined %}{{ rhn.profilename }}{% else %}$(shell hostname -f)_{{ miniascape.builder }}_$(shell date +%Y%m%d_%H%M%S){% endif %}

ifeq ($(RHN_AKEYS),)
rhnreg_ks_OPTIONS ?=
else
rhnreg_ks_OPTIONS ?= --activationkey=$(RHN_AKEYS)
endif

pre_install_OPENSTACK_RPMS ?= yum install -y yum-plugin-priorities
{% if openstack.use_rdo -%}
make_repos_available ?= yum install -y http://rdo.fedorapeople.org/openstack-havana/rdo-release-havana.rpm
install_OPENSTACK_RPMS ?= $(make_repos_available) && yum install -y openstack-packstack
{% elif openstack.use_local -%}
make_repos_available ?= cp $(WORKDIR)/localrepo-rhel7.repo /etc/yum.repos.d
install_OPENSTACK_RPMS ?= $(make_repos_available) && yum install -y openstack-packstack
{% else %}
make_repos_available ?= test -f /etc/sysconfig/rhn/systemid || rhnreg_ks --profilename=$(RHN_PROFILENAME) -v --force $(rhnreg_ks_OPTIONS)
install_OPENSTACK_RPMS ?= $(make_repos_available) && yum install -y \
python-sphinx python-docutils python-jinja2 \
openstack-keystone openstack-utils openstack-selinux \
openstack-swift-proxy openstack-swift-object openstack-swift-container openstack-swift-account \
openstack-glance \
openstack-cinder \
openstack-quantum openstack-quantum-openvswitch openstack-quantum-linuxbridge \
openstack-nova-novncproxy openstack-nova-console \
openstack-nova-api openstack-nova-compute \
openstack-nova-conductor openstack-nova-scheduler \
python-cinderclient \
openstack-dashboard \
nrpe nagios-plugins-nrpe nagios-plugins-ping \
puppet \
openstack-packstack \
$(NULL)
{% endif %}

## TODO: Make the following default for RHOS installation ?
#packstack_OPTIONS ?= --allinone --os-quantum-install=n
#packstack_OPTIONS ?= --allinone
packstack_OPTIONS ?= --answer-file=./answers.txt


all: install
scripts = $(WORKDIR)/glance.sh $(WORKDIR)/install.sh $(WORKDIR)/neutron.sh $(WORKDIR)/nova.sh $(WORKDIR)/service.sh $(WORKDIR)/user_create.sh
utildir = /root/utils


prepare: .prepare.stamp
.prepare.stamp:
	cp $(WORKDIR)/hosts /etc/hosts
	chmod +x $(WORKDIR)/*.sh
	{% if mysql_role is defined %}
	for method in async semisync; do \
		mv $(WORKDIR)/rpl_$${method}_master.cnf $(WORKDIR)/rpl_$${method}_{{ keystone_mysql.master.ip }}.cnf; \
		mv $(WORKDIR)/rpl_$${method}_slave.cnf $(WORKDIR)/rpl_$${method}_{{ keystone_mysql.slave.ip }}.cnf; \
	done
	{% endif -%}

	tar xvf $(WORKDIR)/dotfiles.tar -C /root
	chown -R root:root /root/.ssh
	chmod 700 /root/.ssh
	restorecon -R /root/.ssh

	# for RHEL-OSP + RHS
	setsebool -P sanlock_use_fusefs on
	setsebool -P virt_use_sanlock on
	setsebool -P virt_use_fusefs on
	touch $@

{% if name == "controller" %}
packstack: .packstack.stamp
.packstack.stamp: $(WORKDIR)/update_region_name.sh
	packstack $(packstack_OPTIONS)
	$< {{ region }} 2>&1 | tee log.region
	echo 'export OS_REGION_NAME={{ region }}' >> ~/keystonerc_admin
	touch $@
{% endif %}

{% if hostname == "controller01-1" %}
auth: .auth.stamp
.auth.stamp: $(WORKDIR)/auth_setup.sh
	$< 2>&1 | tee log.auth
	touch $@
{%- endif %}

{% if name == "controller" %}
migrate: .migrate.stamp
.migrate.stamp: $(WORKDIR)/keystone_migrate_db.sh $(WORKDIR)/keystone_migrate_config.sh
{%- if hostname == "controller01-1" %}
	$(WORKDIR)/keystone_migrate_db.sh 2>&1 | tee log.migrate_db
{%- endif %}
	$(WORKDIR)/keystone_migrate_config.sh {{ keystone_mysql.master.ip }} 2>&1 | tee log.migrate_config-{{ keystone_mysql.master.ip }}
{%- if hostname == "controller01-2" %}
	scp 10.0.1.14:keystonerc_{demo,test} /root
	sed -i -e "s/OS_REGION_NAME=.*$\/OS_REGION_NAME={{ region }}/" /root/keystonerc_demo
	sed -i -e "s/OS_REGION_NAME=.*$\/OS_REGION_NAME={{ region }}/" /root/keystonerc_test
{%- endif %}
	touch $@
{%- endif %}

{% if hostname == "auth01-1" %}
endpoint: .endpoint.stamp
.endpoint.stamp: $(WORKDIR)/add_endpoint.sh
	$< keystone Toyama 10.0.1.13 2>&1 | tee log.$(shell basename $<).keystone.Toyama-10.0.1.13
	$< other Toyama 10.0.1.24 2>&1 | tee log.$(shell basename $<).other.Toyama-10.0.1.24
	echo "SELECT endpoint.id, endpoint.legacy_endpoint_id, endpoint.interface, endpoint.region, endpoint.url, endpoint.extra, endpoint.enabled, service.type, service.extra FROM endpoint, service WHERE service.id = endpoint.service_id ORDER BY region,type,interface;" | mysql -uroot -pmysql keystone -t
	touch $@
{%- endif %}

{% if hostname == "controller01-1" %}
#merge: .merge.stamp
#.merge.stamp: $(WORKDIR)/keystone_merge_db.sh
#	$(WORKDIR)/keystone_merge_db.sh 2>&1 | tee log.merge_db
#	touch $@
{%- endif %}

{% if name == "auth" %}
vip: .vip.stamp
.vip.stamp: $(WORKDIR)/keystone_migrate_vip.sh
	ip addr add {{ keystone_ha.service_ip }}/24 dev eth0
	ip addr show dev eth0
	$< 2>&1 {{ keystone_mysql.master.ip }} {{ keystone_ha.service_ip }} | tee log.$(shell basename $<)

replication: .replication.stamp
.replication.stamp: $(WORKDIR)/rpl_setup.sh
	$< 2>&1 | tee log.replication
	#$(WORKDIR)/rpl_status.sh --master {{ keystone_mysql.master.ip }} --slave {{ keystone_mysql.slave.ip }} 2>&1 | tee log.status.before_failover
	#$(WORKDIR)/rpl_status.sh --verbose 2>&1 | tee log.status-v.before_failover

failover: .failover.stamp
.failover.stamp: $(WORKDIR)/rpl_failover.sh
	$< --old-master {{ keystone_mysql.master.ip }} --new-master {{ keystone_mysql.slave.ip }} 2>&1 | tee log.failover
	#$(WORKDIR)/rpl_status.sh --master {{ keystone_mysql.slave.ip }} --slave {{ keystone_mysql.master.ip }} 2>&1 | tee log.status.after_failover
	#$(WORKDIR)/rpl_status.sh --verbose 2>&1 | tee log.status-v.after_failover
{%- endif %}

{% if name == "controller" %}
user: .user.stamp
.user.stamp: $(WORKDIR)/install.sh
{%- if hostname == "controller01-1" %}
	$(WORKDIR)/install.sh 2>&1 | tee log.install.sh
{%- elif hostname == "controller01-2" %}
	$(WORKDIR)/tenant_setup.sh demo 2>&1 | tee log.tenant_setup.sh-demo
	$(WORKDIR)/tenant_setup.sh test 2>&1 | tee log.tenant_setup.sh-test
{%- endif %}
	touch $@

image: .image.stamp
.image.stamp: $(WORKDIR)/glance.sh
	$< 2>&1 | tee log.$(shell basename $<)
	touch $@

network: .network.stamp
.network.stamp: $(WORKDIR)/neutron.sh
	$< -t demo -R router-demo -n public-demo -c {{ neutron.external.cidr }} router-create 2>&1 | tee log.$(shell basename $<).router-create
	$< -t demo -R router-demo -n demo-net -c {{ neutron.tenant.cidr }} create 2>&1 | tee log.$(shell basename $<).create
	touch $@

vm: .vm.stamp
.vm.stamp: $(WORKDIR)/vm_test.sh
	$< 2>&1 | tee log.$(shell basename $<)

volume: .volume.stamp
.volume.stamp: $(WORKDIR)/cinder.sh
	$< 2>&1 | tee log.$(shell basename $<)
{%- endif %}

.PHONY: prepare packstack db_merge vip_set vip_unset keystone_ha replication failover users glance
.PHONY: .prepare.stamp .packstack.stamp

