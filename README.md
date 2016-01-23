##### photo-db

#### todo

## mongo db connection reuse across namespaces

if image is not persisted in right stores ( store not available, etc. ) we should store request in task queue and execute it later ( each task should have required stores )


#### simple import procedure

## download images from dslr to /tmp/import_yyyyMMdd
## run process 
	curl -D '{
				"path": "/tmp/import_yyyyMMdd"
				"tag": "import_yyyyMMdd"}'
		http://photodb-uri/api/process-path'
## explore images 
	with http://photodb-uri/web/explore&tags=import_yyyyMMdd
	or with ipad app

### run process will do following
	## create new tag given in request
	## extract are images in given path
	## per each image in path
		# extract metadata
		# see if we have raw of this photo ( same name instead .nef )
		# create thumbnail
		# create preview
		# ensure stores ( in future we should write to temporary store and create sync requests )

### explore images will do following
	## identify images that contain given tags 
	## create thumbnail image urls and return them

#### goal
create env for photo storage, tagging, browsing, thumbnailing, autodiscovery of new images ...

#### entities 

### image
represents one image taken in various forms
## file representations
# raw - raw image obtained from dslr
# jpg - jpg image obtained from dslr
# thumbnail - thumbnail made from jpg, to be used by photodb when in explore mode
# preview - preview made from jpg to be used by photodb when in image mode
## metadata representation
# id - created by using checksum on raw or jpg, if raw exists use raw ...

#### hackaton 1
one day left, idea

## copy images from DSLR SD card
## run process-path, will trigger N process-image
## process-image will 
# extract id
# extract metadata
# create thumbnail
# create preview
# store in root-store ( simple for now, will store everything )


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


