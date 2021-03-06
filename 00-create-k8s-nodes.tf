##Setup needed variables
variable "node-count" {}
variable "internal-ip-pool" {}
variable "floating-ip-pool" {}
variable "image-name" {}
variable "image-flavor" {}
variable "security-groups" {}
variable "key-pair" {}

##Create a single master node and floating IP
resource "openstack_compute_floatingip_v2" "master-ip" {
  pool = "${var.floating-ip-pool}"
}

resource "openstack_compute_instance_v2" "k8s-master" {
  name = "k8s-master"
  image_name = "${var.image-name}"
  flavor_name = "${var.image-flavor}"
  key_pair = "${var.key-pair}"
  security_groups = ["${split(",", var.security-groups)}"]
  network {
    name = "${var.internal-ip-pool}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "k8s-master" {
    floating_ip = "${element(openstack_networking_floatingip_v2.master-ip.address)}"
    instance_id = "${element(openstack_compute_instance_v2.k8s-master.*.id, count.index)}"
}

##Create desired number of k8s nodes and floating IPs
resource "openstack_compute_floatingip_v2" "node-ip" {
  pool = "${var.floating-ip-pool}"
  count = "${var.node-count}"
}

resource "openstack_compute_instance_v2" "k8s-node" {
  count = "${var.node-count}"
  name = "k8s-node-${count.index}"
  image_name = "${var.image-name}"
  flavor_name = "${var.image-flavor}"
  key_pair = "${var.key-pair}"
  security_groups = ["${split(",", var.security-groups)}"]
  network {
    name = "${var.internal-ip-pool}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "k8s-node" {
    floating_ip = "${element(openstack_networking_floatingip_v2.node-ip.*.address, count.index)}"
    instance_id = "${element(openstack_compute_instance_v2.k8s-node.*.id, count.index)}"
}
