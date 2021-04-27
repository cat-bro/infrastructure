# application server / web server
resource "openstack_compute_instance_v2" "galaxy-cat" {
 availability_zone = "melbourne-qh2-uom"
 name = "galaxy-cat"
 flavor_name = "uom.general.2c8g"
 key_pair = "nectartest"
 image_name = "NeCTAR Ubuntu 20.04 LTS (Focal) amd64"
 security_groups = ["SSH", "Web-Services"]
}

## Volume for application/web server
resource "openstack_blockstorage_volume_v2" "galaxy-cat-volume" {
 availability_zone = "melbourne-qh2-uom"
 name        = "galaxy-cat-volume"
 description = "galaxy-cat volume"
 size        = 80
}

## Attachment between application/web server and volume
resource "openstack_compute_volume_attach_v2" "attach-galaxy-cat-volume-to-galaxy-cat" {
 instance_id = "${openstack_compute_instance_v2.galaxy-cat.id}"
 volume_id   = "${openstack_blockstorage_volume_v2.galaxy-cat-volume.id}"
}
