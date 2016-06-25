# sat6-disconnected Example Scripts and Configs

Please note that these config files and scripts are not official Red Hat software, and are provided as examples for what may be necessary to accomplish a Disconnected installation of OpenShift and Satellite 6.  Please contact taylor@redhat.com if you have any concerns, questions or issues.  Pull requests are always appreciated!

Contents:

* docker_list_images.py  
a script that will list all images available on registry.access.redhat.com.  Primarily for use by docker_save.sh  
* docker_save.sh  
a script that will pull each image found (per a specific regex), and save it to the local disk  
* docker_load.sh   
a script that will push each image found on local disk to a local Docker registry  
*  docker_push.sh  
a script that will re-tag each image on the local disk to the appropriate corporate registry address, and push them to the registry  
* sample_etc_ansible_hosts  
a file that shows example settings for using a local, disconnected registry while installing OpenShift Enterprise in "Advanced" mode  


Since the current version of Satellite (6.2 beta 2) doesn't have a "hammer" CLI call to start a content-view export, you can use the following CURL syntax to do so.  The below assumes username "admin" and password "password", and exports Content View number 1, which is typically the entire Library (all available items on the server) downloaded on or after June 1, 2016.  The output will be in the "exports" folder, as configured by Satellite (see Satellite documentation for other exporting features).  
  
`curl -X POST -H "Accept:application/json,version=2" -H "Content-Type:application/json" -d "{\"id\":\"1\",\"since\":\"2016-06-01T00:00:00Z\"}"  -u admin:password https://localhost//katello/api/content_view_versions/1/export  -k`
