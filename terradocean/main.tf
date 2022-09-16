# main.tf

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
# token = "dop_v1_0354c5555217de8bc5173e3be507dd83dcaf1293c4cb9c7029daafc905dfccad"
}

data "digitalocean_ssh_key" "terradocean" {
  name = "terradocean"
}


####

locals {
  farmgroups = {
    "doin" = {
      reg_suffix  = "in"
      location    = "blr1"
    }
    "dosg" = {
      reg_suffix  = "sg"
      location    = "sgp1"
    }
  }
}

locals {
  vm_idxx   = [ 0, 1, 2 ]
  groups_vms = distinct(flatten([
    for farm_group in local.farmgroups : [ 
      for vm_idx in local.vm_idxx : { 
        reg_suffix = farm_group.reg_suffix
        location = farm_group.location
        vm_idx = vm_idx
      }
    ]
  ]))
}

# vm's

resource "digitalocean_droplet" "do_vm" {
  for_each = { 
    for i in local.groups_vms: "${i.reg_suffix}.${i.vm_idx}" => i 
  }
  name      = "do${each.value.reg_suffix}${each.value.vm_idx}"
  image     = "debian-11-x64"
  region    = each.value.location
  size      = "s-1vcpu-1gb-intel"

  ssh_keys = [
    data.digitalocean_ssh_key.terradocean.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file("~/.ssh/id_rsa")
    timeout = "1m"
  }

  # n.b. it's a dash sript by default
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "useradd -s /bin/bash -d /home/${var.admin_name} -m ${var.admin_name} && echo ${var.admin_pw}\\\\n${var.admin_pw} | passwd ${var.admin_name} && gpasswd -a ${var.admin_name} sudo", 
      "A=$(cp /etc/ssh/sshd_config /etc/ssh/sshd_config.00 && cat /etc/ssh/sshd_config | sed -r 's/_/UNDERSCORE/g' | tr \\n _ | sed -r 's/PasswordAuthentication no/PasswordAuthentication yes/' | sed -r 's/_/\\n/g' | sed -r 's/UNDERSCORE/_/g') && echo -e $A > /etc/ssh/sshd_config && systemctl restart ssh.service", 
      var.install_spec_soft,
    ]
  }
}
  
