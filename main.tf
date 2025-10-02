terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.45.0"
    }
  }
  required_version = ">= 1.0.0"
}


# ----- PARTIE PROVIDER ------- #

provider "openstack" {
  user_name = "gestion"
  password  = "salles123"
  auth_url  = "http://10.20.112.64/identity"
  project_name = "salles-seminaires"
  user_domain_name = "default"
  project_domain_name = "default"
}


# ----- PARTIE GROUPE SECURITE ------- #

#Groupe securite creation
resource "openstack_networking_secgroup_v2" "vm_secgroup" {
name = "vm-secgroup"
}

#SSH
resource "openstack_networking_secgroup_rule_v2" "ssh_rule" {
direction = "ingress"
ethertype = "IPv4"
protocol = "tcp"
port_range_min = 22
port_range_max = 22
security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
}

#TCP
resource "openstack_networking_secgroup_rule_v2" "http_rule" {
direction = "ingress"
ethertype = "IPv4"
protocol = "tcp"
port_range_min = 80
port_range_max = 80
security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
}


#ICMP
resource "openstack_networking_secgroup_rule_v2" "icmp" {
direction = "ingress"
ethertype = "IPv4"
protocol = "icmp"
security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
}


# ----- PARTIE RESEAU ------- #

#Creation du reseau
resource "openstack_networking_network_v2" "private_net" {
  name = "private_net"
}

#Creation du sous-reseau
resource "openstack_networking_subnet_v2" "subnet" {
  name       = "subnet_net1"
  network_id = openstack_networking_network_v2.private_net.id
  cidr       = "192.168.50.0/24"
  ip_version = 4
  gateway_ip = "192.168.50.1"
  dns_nameservers = ["8.8.8.8"]
}

# ----- Routeur connecté au public -----
resource "openstack_networking_router_v2" "router_cloud" {
  name                = "router1_cloud"
  external_network_id = "public"  # réseau public
}


#Attacher le subnet privé à ce routeur 

resource "openstack_networking_router_interface_v2" "router_cloud" {
  router_id = openstack_networking_router_v2.router_cloud.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}


# --- VM Cirros

resource "openstack_compute_instance_v2" "cirros" {
  name        = "cirros-vm"
  flavor_name = "m1.tiny"
  image_name  = "cirros-0.6.3-x86_64-disk"
  key_pair    = "salles-seminaires-key"

  network {
    uuid = openstack_networking_network_v2.private_net.id
  }
 security_groups = [openstack_networking_secgroup_v2.vm_secgroup.id]
}



# --- VM Linux ---

resource "openstack_compute_instance_v2" "ubuntu_vm" {
  name = "ubuntu-vm"
  image_name  = "Ubuntu-salles"
  flavor_name = "salles.gabarit"
  key_pair    = "salles-seminaires-key"

  network {
    uuid = openstack_networking_network_v2.private_net.id
  }

  security_groups = [openstack_networking_secgroup_v2.vm_secgroup.id]
}




# --- Floating IP ---
resource "openstack_networking_floatingip_v2" "fip" {
  pool = "public"
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  instance_id = openstack_compute_instance_v2.ubuntu_vm.id
}
