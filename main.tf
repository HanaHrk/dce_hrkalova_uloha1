terraform {
      required_providers {
    opennebula = {
      source = "OpenNebula/opennebula"
      version = "~> 1.3"
    }
  }
}

provider "opennebula" {
  endpoint = "https://nuada.zcu.cz/RPC2"
  username      = "${var.one_username}"
  password      = "${var.one_password}"  
}

resource "opennebula_image" "os-image" {
    name = "${var.vm_image_name}"
    datastore_id = "${var.vm_imagedatastore_id}"
    persistent = false
    path = "${var.vm_image_url}"
    permissions = "600"
}



# Create template for frontend
resource "opennebula_virtual_machine" "frontend_vm_template" {
  name        = "frontend-template"
  cpu         = 1
  vcpu        = 1
  memory      = 1024
  permissions = "600"
  group       = "users"

  os {
    arch = "x86_64"
    boot = "disk0"
  }
  
  disk {
    image_id = opennebula_image.os-image.id
    target   = "vda"
    size     = 12000 # 12GB
  }

  graphics {
    listen = "0.0.0.0"
    type   = "VNC"
  }

  nic {
    network_id = var.vm_network_id  # update with actual network id
  }
  context = {
    NETWORK  = "YES"
    HOSTNAME = "$NAME"
    SSH_PUBLIC_KEY = "${var.vm_ssh_pubkey}"
  }
  connection {
    type = "ssh"
    user = "root"
    host = "${self.ip}"
    private_key = "${file("/var/id_ecdsa")}"
  }
   provisioner "file" {
    source = "init-scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "export INIT_USER=${var.vm_admin_user}",
      "export INIT_PUBKEY='${var.vm_ssh_pubkey}'",
      "export INIT_LOG=${var.vm_node_init_log}",
      "export INIT_HOSTNAME=${self.name}",
      "touch ${var.vm_node_init_log}",
      "sh /tmp/init-start.sh",
      "sh /tmp/init-node.sh",
      "sh /tmp/init-users.sh",
      "sh /tmp/init-finish.sh"
    ]
  }


}

# Create template for backend
resource "opennebula_virtual_machine" "backend_vm_template" {
  count = var.compute_nodes_count
  name = "backend-vm-${count.index + 1}"
  cpu         = 1
  vcpu        = 1
  memory      = 1024
  permissions = "600"
  group       = "users"

  os {
    arch = "x86_64"
    boot = "disk0"
  }
  
  disk {
    image_id = opennebula_image.os-image.id
    target   = "vda"
    size     = 12000 # 12GB
  }

  graphics {
    listen = "0.0.0.0"
    type   = "VNC"
  }

  nic {
    network_id = var.vm_network_id  # update with actual network id
  }
  context = {
    NETWORK  = "YES"
    HOSTNAME = "$NAME"
    SSH_PUBLIC_KEY = "${var.vm_ssh_pubkey}"
  }
  connection {
    type = "ssh"
    user = "root"
    host = "${self.ip}"
    private_key = "${file("/var/id_ecdsa")}"
  }
    provisioner "file" {
    source = "init-scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "export INIT_USER=${var.vm_admin_user}",
      "export INIT_PUBKEY='${var.vm_ssh_pubkey}'",
      "export INIT_LOG=${var.vm_node_init_log}",
      "export INIT_HOSTNAME=${self.name}",
      "touch ${var.vm_node_init_log}",
      "sh /tmp/init-start.sh",
      "sh /tmp/init-node.sh",
      "sh /tmp/init-users.sh",
      "sh /tmp/init-finish.sh"
    ]
  }
}
  

#Create VMs based on frontend template
#resource "opennebula_virtual_machine" "fe_vm" {
#  count        = 1
#  name         = "frontend-vm"
# }

# Create VMs based on backend template
#resource "opennebula_virtual_machine" "be_vm" {
#  count        = 2
#  name         = "backend-vm-${count.index + 1}"
# }

#resource "null_resource" "install_nginx" {
#  connection {
#    type        = "ssh"
#    user        = "root"
#    private_key = "${file("/var/id_ecdsa")}"
#    host        = opennebula_virtual_machine.frontend_vm_template.ip   
#  }
#  
#  provisioner "remote-exec" {
#    inline = [
#      "sudo yum install epel-release nginx -y",
#      "sudo rm -rf /usr/share/nginx/html",
#    ]
#  }#

#  provisioner "file" {
#    source      = "./frontend/config/backend-upstream.conf"#
 #   destination = "/etc/nginx/conf.d/backend-upstream.conf"
#  }
#
#  provisioner "file" {
#    source      = "./frontend/config/backend-proxy.conf"
#    destination = "/etc/nginx/default.d/backend-proxy.conf"
#  } #
#
#  provisioner "remote-exec" {
#    inline = [
#      "sudo systemctl start nginx",
#      "sudo systemctl enable nginx",
#    ]
#  }
#}

#--------- OUTPUTS ------------

output "frontend_vm_template" {
  value = "${opennebula_virtual_machine.frontend_vm_template.*.ip}"
}

output "backend_vm_templates" {
  value = "${opennebula_virtual_machine.backend_vm_template.*.ip}"
}

#--------- RESOURCES ------------
resource "local_file" "hosts_cfg" {
  content = templatefile("inventory.tmpl",
    {
      vm_admin_user = var.vm_admin_user,
      frontend_vm_template = opennebula_virtual_machine.frontend_vm_template.*.ip,
      backend_vm_templates = opennebula_virtual_machine.backend_vm_template.*.ip
    })
  filename = "./dynamic_inventories/inventory"
}



resource "local_file" "upstream_cfg" {
  content = templatefile("upstream.tmpl",
    {
      backend_vm_templates = opennebula_virtual_machine.backend_vm_template.*.ip
    })
  filename = "./frontend/config/backend-upstream.conf"
}



