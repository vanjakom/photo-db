(ns photodb-server.core)

;(require '[clojure-repl.logging :as logging])
(require 'clojure.pprint)

(require 'monger.core)
(require '[monger.collection :as mongo])

(require '[photodb-server.executor 	:as executor])
(require '[photodb-server.manage 	:as manage])
(require '[photodb-server.store 	:as store])

(require '[clojure-repl.fs.utils 	:as fs-utils])
(require '[clojure-repl.fs.io 		:as fs-io])
(require '[clojure-repl.fs.stream	:as fs-stream])
(require '[clojure-repl.image.exif 	:as exif-utils])
(require '[clojure-repl.misc.utils 	:as misc-utils])
(require '[clojure-repl.image.core 	:as image-utils])

; way to write pipeline based code
; define private context initialize ( extract params )
; define *-api public func which accepts params as args and constructs context
; declare same fn without api which accepts context

; concept of pipeline
; intial function is *-context, one that creates context
; all functions in chain are f(context) -> context
; if not needed because of optimizations context should be only built up
; extraction of return value is done in main function called from *-api

; process path api
(declare process-path)
(defn- process-path-context [path tags]
	{
		:tags tags
		:path path
		:updated (System/currentTimeMillis)})
(defn process-path-api 
	"Entry point from API."
	[path tags]
	(executor/async-backend-request process-path (process-path-context path tags)))

; render image api
(declare render-image)
(defn- render-image-context [id type]
	{
		:id id
		:type type})
(defn render-image-api
	"Renders image based on id and type, returns stream which represents jpeg image"
	[id type]
	(render-image (render-image-context id type)))

; tag view api
(declare tag-view)
(defn- tag-view-context [tags] { :tags tags })
(defn tag-view-api
	"Returns image id list for given tags combination. Images should be sorted in order
	in which should be represented to user"
	[tags]
	(tag-view (tag-view-context tags)))

; tag list api
(declare tag-list)
(defn- tag-list-context [] {})
(defn tag-list-api
	"Returns list of tags ( with some metadata ) available"
	[]
	(tag-list (tag-list-context)))

; setup db connection
(defonce ^:private db 
	(let [connection (monger.core/connect {:host "localhost" :port 27017})]
		(monger.core/get-db connection "photodb")))

(def ^:const ^:private thumbnail-square-dimension 150)
(def ^:const ^:private preview-dimension 1280)

; transformers

(defn- process-image-context [path tags]
	{
		:path path
		:tags tags})

(defn- ensure-tags [context]
	(let [{	tags :tags} context]
		(doseq [tag tags]
			(manage/tag-create-if-not-exists tag))
		context))

(defn- original-bytes [context] 
	(let [{	path :path} context]
		(assoc context :original-bytes (fs-io/read-file-to-byte-array path))))

(defn- original [context]
	(let [	{original-bytes :original-bytes} context]
		(assoc context :original (image-utils/create-image-from-bytes original-bytes))))

(defn- photo-id [context]
	(let [ 	{original-bytes :original-bytes} context]
		(assoc context :id (misc-utils/md5sum-byte-array original-bytes))))

(defn- extract-metadata [context]
	(let [{	original-bytes :original-bytes
			id :id
			path :path
			tags :tags} context]
		(let [	exif-metadata (exif-utils/extract-photo-exif original-bytes)
				timestamp (System/currentTimeMillis)
				creation-timestamp 
					(if-let [exif-date (:date (:exif exif-metadata))]
						(exif-utils/exif-date-to-timestamp exif-date)
						timestamp)
				initial-metadata {
					:id id
					:tags tags
					:created creation-timestamp
					:updated timestamp }]
			(assoc context :metadata (conj exif-metadata initial-metadata)))))

(defn- find-raw-image-bytes [context]
	(let [{	path :path} context]
		(assoc context :raw-bytes nil)))

(defn- rotate-original-if-needed [context]
	(let [{	metadata :metadata
			original :original} context]
		(if-let [exif-orientation (:orientation metadata)]
			(let [original-normalized (image-utils/normalize-image-on-exif-rotation original exif-orientation)]
				(assoc context :original-normalized original-normalized))
			(assoc context :original-normalized (:original context))
			)))

(defn- create-thumbnail-square [context]
	(let [{	original-normalized :original-normalized} context]
		(assoc context 
			:thumbnail-square 
			(image-utils/create-thumbnail-square original-normalized thumbnail-square-dimension))))

(defn- extract-thumbnail-square-bytes [context]
	(let [{	thumbnail-square :thumbnail-square} context]
		(assoc context
			:thumbnail-square-bytes (image-utils/write-image-to-bytes thumbnail-square))))

(defn- create-preview [context]
	(let [{	original-normalized :original-normalized} context]
		(assoc context 
			:preview 
			(image-utils/create-thumbnail original-normalized preview-dimension))))

(defn- extract-preview-bytes [context]
	(let [{	preview :preview} context]
		(assoc context
			:preview-bytes
			(image-utils/write-image-to-bytes preview))))

(defn- write-to-stores [context]
	(let [{	metadata :metadata
			raw-bytes :raw-bytes
			original-bytes :original-bytes
			preview-bytes :preview-bytes
			thumbnail-square-bytes :thumbnail-square-bytes} context]
		(store/ensure-stores metadata raw-bytes original-bytes preview-bytes thumbnail-square-bytes)
		context))

(defn- write-to-db [context]
	(let [{	metadata :metadata
			id :id} context]
		(manage/image-create (assoc metadata :_id id))
		context))

(defn- print-context [context]
	(clojure.pprint/pprint (dissoc context 
		:raw-bytes :original-bytes :thumbnail-square-bytes :preview-bytes :original-normalized))
	context)

(defn- process-image [context]
	(->
		context
		ensure-tags
		original-bytes
		original
		photo-id
		extract-metadata
		find-raw-image-bytes
		rotate-original-if-needed
		create-thumbnail-square
		extract-thumbnail-square-bytes
		create-preview
		extract-preview-bytes		
		write-to-stores
		write-to-db))

(defn- process-path [context]
	(let [{	path :path
			tags :tags} context]
		(doseq [image (fs-utils/filter-images-only (fs-utils/list-path path))]
			(executor/async-backend-request process-image (process-image-context image tags)))))

(defn- retrive-image-metadata [context]
	(let [{	id :id} context]
		(assoc context :metadata (manage/image-get id))))

(defn- retrieve-image [context]
	(let [{	metadata :metadata 
			type :type} context]
		(assoc context :image (store/get-image metadata type))))

(defn- render-image [context]
	(:image 
		(->
			context
			retrive-image-metadata
			retrieve-image)))

(defn- find-suitable-images [context]
	(let [	{tags :tags} context]
		(assoc context :images (manage/images-find tags))))

(defn- extract-image-ids [context]
	(let [	{images :images} context]
		(assoc context :ids (map :id images))))

(defn- tag-view [context]
	(:ids 
		(->
			context
			find-suitable-images
			extract-image-ids)))

(defn- get-all-tags [context]
	(assoc context :tags (manage/tags-list)))

(defn- process-tags [context]
	(let [{	tags :tags} context]
		(assoc context :prepared-tags (map (fn [tag] {:name (:id tag)}) tags))))

(defn- tag-list [context]
	(:prepared-tags
		(->
			context
			get-all-tags
			process-tags)))





