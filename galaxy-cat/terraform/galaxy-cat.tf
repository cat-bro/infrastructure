# application server / web server
resource "openstack_compute_instance_v2" "galaxy-cat" {

}

## Volume for application/web server
#resource "openstack_blockstorage_volume_v2" "galaxy-cat-volume" {
#  availability_zone = "melbourne-qh2"
#  name        = "galaxy-cat-volume"
#  description = "galaxy-cat volume"
#  size        = 100
#}

## Attachment between application/web server and volume
#resource "openstack_compute_volume_attach_v2" "attach-dev-volume-to-dev" {
#  instance_id = "${openstack_compute_instance_v2.galaxy-cat.id}"
#  volume_id   = "${openstack_blockstorage_volume_v2.galaxy-cat-volume.id}"
#}
