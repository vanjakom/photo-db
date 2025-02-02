# photo-db

## note

Code is not currently in stage in which it could be useful to someone.

## hackaton 2, setup

will drop all mongo db tables and create default env
; (photodb-server.setup/setup)

setup of mongodb / start

cd ~/install/mongodb
bin/mongod --dbpath ~/install/mongodb-data/

lein repl

(photodb-server.main/-main)


## image import @north2018

curl -H "Content-Type:application/json" -d '{"path":"/Volumes/STORAGE/pictures/2018/2018.07 - @north2018", "tags":["2018.07 - @north2018", "@north2018"]}' 'http://localhost:8988/api/admin/process-path'

db.backend_queue.find({"status":{$ne:"done"}}).count()

http://localhost:8988/render/tag/view?tags=@north2018&type=preview

## image import

procedure
import images to one of photo stores ( /Users/vanja/Pictures/ ), name directory as album title ( YYYY.MM - TITLE ), leave names as DSLR named them, put both originals and raws into single directory
ensure photodb server is live, mongodb set up
call process

curl -H "Content-Type:application/json" -d '{"path":"/Volumes/STORAGE/pictures/2018/2018.01 - New Year in Scotland", "tags":["2018.01 - New Year in Scotland"]}' 'http://localhost:8988/api/admin/process-path'

ensure all images are imported

db.backend_queue.find({"status":{$ne:"done"}}).count()

should return zero

http://localhost:8988/render/tag/view?tags=2018.01%20-%20New%20Year%20in%20Scotland&type=preview

either full screen or most of screen in Safari
write down ids which will go into album


## useful links

curl -H "Content-Type:application/json" -d '{}' 'http://localhost:8988/api/tag/list'

curl -H "Content-Type:application/json" -d '{"path":"/Users/vanja/Pictures/20151219 - New pictures", "tags":["20151219 - New pictures"]}' 'http://localhost:8988/api/admin/process-path'

curl -H "Content-Type:application/json" -d '{"path":"/Users/vanja/Pictures/20151213 - New pictures", "tags":["20151213 - New pictures"]}' 'http://localhost:8988/api/admin/process-path'

curl -H "Content-Type:application/json" -d '{"path":"/Users/vanja/Pictures/20151212 - New pictures", "tags":["20151212 - New pictures"]}' 'http://localhost:8988/api/admin/process-path'

curl -H "Content-Type:application/json" -d '{"path":"/Volumes/STORAGE/pictures/2016/2016.02 - RoadTrip Poland/", "tags":["2016.02 - RoadTrip Poland"]}' 'http://localhost:8988/api/admin/process-path'


(in-ns 'photodb-server.core)
(ensure-tags {:tags ["#art" "#life"]})
(ensure-tags {:tags ["#album"]})

## useful

db.backend_queue.find({"status": {$ne: "done"}}).count()

db.images.find({"tags": { $in: ["2014.09 - RoadTrip Greece, Elafonosis Nikon"]}}).count()

db.images.find({"tags": {$in: ["2016.02 - RoadTrip Poland"]}})

## in case of import error

drop mongodb requests ( they will not be resubmitted, mongodb is used only for tracking )

db.backend_queue.remove({"status":{$ne:"done"}})

send process-path request again

## idea

Store raw / original jpg images on one place and have access to preview / thumbnail always. Since preview and thumbain is ~ 100x smaller I could store all of my images on laptop disk and originals only of ones I really, really want.

Image cannot be classified only by one criteria ( folder name ), instead images are classified with multiple criterias, tags. Example: ["RoadTrip Greece 2012" "#best2012" "#sea" "#art"], where "RoadTrip Greece 2012" tells that image belongs to album and "#best2012", "#sea" and "#art" tell other characteristics.

I don't like to edit images. Once taken, image represents place and time, no need to edit it.

Laptop screen is to disruptive to view images, watch them in, as close to printed form, iPad screen.




## todo

mongo db connection reuse across namespaces

if image is not persisted in right stores ( store not available, etc. ) we should store request in task queue and execute it later ( each task should have required stores )


simple import procedure

download images from dslr to /tmp/import_yyyyMMdd

run process
	curl -D '{
				"path": "/tmp/import_yyyyMMdd"
				"tag": "import_yyyyMMdd"}'
		http://photodb-uri/api/process-path'
explore images
	with http://photodb-uri/web/explore&tags=import_yyyyMMdd
	or with ipad app

run process will do following
	create new tag given in request
	extract are images in given path
	per each image in path
		extract metadata
		see if we have raw of this photo ( same name instead .nef )
		create thumbnail
		create preview
		ensure stores ( in future we should write to temporary store and create sync requests )

explore images will do following
	identify images that contain given tags
	create thumbnail image urls and return them

goal
create env for photo storage, tagging, browsing, thumbnailing, autodiscovery of new images ...

## entities

### image
represents one image taken in various forms
#### file representations
##### raw - raw image obtained from dslr
##### jpg - jpg image obtained from dslr
##### thumbnail - thumbnail made from jpg, to be used by photodb when in explore mode
##### preview - preview made from jpg to be used by photodb when in image mode
##### metadata representation
##### id - created by using checksum on raw or jpg, if raw exists use raw ...

### hackaton 1
one day left, idea

### copy images from DSLR SD card
### run process-path, will trigger N process-image
### process-image will
#### extract id
#### extract metadata
#### create thumbnail
#### create preview
#### store in root-store ( simple for now, will store everything )


#### relation between image <> metadata <>  root-store

based on image (raw or jpeg) md5sum is generated, md5sum + exif info + metadata will produce
metadata, from image thumbnail, preview is generated

metadata is stored in mongo db

initial root store will be fs


image:

{
	:id "<hash_1>"
	:metadata {
		:exif {
			:orientation 8
			:make "Nikon"}
		:size {
			:width <width>
			:height <height>
		:created <timestamp>
		:updated <timestamp>
		:original-filename "DSC-0001"
		:original-path "2016.01 - Life"}}
	:tags (
		"2016.01 - Life")}
{
	:id "<hash_1>"
	:metadata {
		:exif {
			:orientation 8
			:make "Nikon"}
		:size {
			:width <width>
			:height <height>
		:created <timestamp>
		:updated <timestamp>
		:original-filename "DSC-0002"
		:original-path "2016.01 - Life"}}}
	:tags (
		"2016.01 - Life"
		"best 2016")}

tag:

{
	:id "2016.01 - Life"
	:stores (
		[:laptop-store (:metadata :thumbnail :preview)]
		[:backup-store (:all)]}}
{
	:id "best 2016"
	:stores {
		[:laptop-store (:all)]
		[:backup-store (:all)]}}

root store:

{
	:id laptop-store
	:path "/Users/vanja/photo-db"
	:patterns {
		:metadata {
			:type "mongo-db"}
		:thumbnails {
			:type "photo-db"}
		:preview {
			:type "photo-db"}
		:raw {
			:type "photo-db"}
		:jpeg {
			:type "photo-db"}}}
{
	:id backup-store
	:path "/Users/vanja/photo-db"
	:patterns {
		:metadata {
			:type "photo-db"}
		:thumbnails {
			:type "photo-db"}
		:preview {
			:type "photo-db"}
		:raw {
			:type "human-format"}
		:jpeg {
			:type "human-format"}}}


