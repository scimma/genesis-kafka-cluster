##
## Variables: these are the things that you can override on the command
## line, or using .tfvars files.
##

variable "do_token" {}						# Your Digital Ocean API access token

variable "num_brokers" {}                                       # Number of brokers in the Kafka cluster

variable "domain"   {}                                          # The domain name of the broker. The domain must be under Digital Ocean DNS control.
								# The default will create machines in the test domain; override on the command line
								# to create in the production domain.

##
## You should rarely need to override these:
##

variable "broker_size" { default = "s-6vcpu-16gb" }		# Digital Ocean instance type for the broker machine
variable "monitor_size" { default = "s-2vcpu-2gb" }		# Digital Ocean instance type for the monitor machine

variable "broker_hostname"  { default = "broker" }              # hostname of the broker
variable "monitor_hostname" { default = "status" }              # hostname of the monitor

#
# Fingerprint of the key to use for SSH-ing into the newly created machines.
# The key must be already uploaded to Digital Ocean via the web interface.
#
variable "ssh_fingerprint" { default = [ 
	"57:c0:dd:35:2a:06:67:d1:15:ba:6a:74:4d:7c:1c:21",
	"cd:78:d0:36:19:95:59:80:66:d9:e2:c9:39:52:80:c3",
	"37:70:f2:46:82:98:fc:a4:bf:d3:8c:38:1d:dd:b8:68"
] }

#################################################################################
#
# Compute useful local variables, set up DO provider, domain
#

locals {
  monitor_fqdn = "${var.monitor_hostname}.${var.domain}"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

provider "openstack" {
}

resource "digitalocean_domain" "default" {
   name = "${var.domain}"

   lifecycle {
     # This is to prevent accidentally destroying the whole (sub)domain; there
     # may be other entries in it that are not managed by terraform.
     prevent_destroy = true
   }
}

#################################################################################
#
#  The broker machine. Runs zookeeper, kafka, mirrormaker, and Prometheus
#  metrics exporters.
#
#################################################################################

resource "openstack_compute_instance_v2" "broker" {
  count = "${var.num_brokers}"

  image_id = "152a40ae-590d-4758-b335-98365795cf26"
  name = "${var.broker_hostname}${count.index}.${var.domain}"
  key_pair = "caladan"
  security_groups = ["default"]
  flavor_name = "c1.m8"

  block_device {
    uuid                  = "152a40ae-590d-4758-b335-98365795cf26"
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "public"
  }

  network {
    name = "private"
  }
}
