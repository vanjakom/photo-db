(ns photodb-server.store)

(require '[clojure-repl.fs.utils :as fs-utils])
(require '[clojure-repl.fs.io :as fs-io])
(require '[clojure-repl.image.core :as image-utils])

(declare get-stores)

(defn ensure-stores 
	"should for given image-metadata and appropriate images
	store image representations to adequate stores in case store 
	is not available image representation ( metadata, images ...)
	should be stored in temporary store and request written to queue"
	[^clojure.lang.IPersistentMap image-metadata 
	^bytes raw
	^bytes original
	^bytes preview
	^bytes thumbnail-square]

	; initial implementation will write to default store only
	; CORRECTION: initial implementation will write preview and thumbnail
	; and will write everything
	; todo use tags to understand to which stores to write

	(let [	store (:default-store (get-stores))
			functions (:preview-and-thumbnail store)
			write-function (second functions)]
		(write-function image-metadata raw original preview thumbnail-square)))

(defn ^bytes get-image [image-metadata type]
	; todo use tags to understand which store to query
	(let [	store (:default-store (get-stores))
			functions (type store)
			read-function (first functions)]
		(read-function image-metadata)))

(defn- read-image-from-store-human [store-path id type]
	; todo
	)

(defn- write-image-to-store-human [store-path image-metadata image type]
	; todo
	)

(defn- full-path-for-image-photodb [store-path id type]
	(let [	suffix (cond
						(= type :raw) "_raw.nef"
						(= type :original) "_original.jpg"
						(= type :preview) "_preview.jpg"
						(= type :thumbnail-square) "_thumbsquare.jpg")]
		(fs-utils/make-path store-path (str id suffix))))

(defn- ^bytes read-bytes-from-store-photodb [store-path image-metadata type]
	(let [	final-path (full-path-for-image-photodb store-path (:id image-metadata) type)]
		(fs-io/read-file-to-byte-array final-path)))

; (defn- write-image-to-store-photodb 
; 	"Write image calls always expect BufferedImage on input"
; 	[store-path image-metadata ^java.awt.image.BufferedImage image type]
; 	(let [	final-path (full-path-for-image-photodb store-path (:id image-metadata) type)]
; 		(image-utils/write-image-to-path image final-path)))

(defn- write-bytes-to-store-photodb
	[store-path image-metadata ^bytes bytes type]
	(let [	final-path (full-path-for-image-photodb store-path (:id image-metadata) type)]
		(fs-io/write-file-from-byte-array bytes final-path)))

(defn- get-stores 
	"Returns stores setup. Stores are represented as maps where key is store keyword and value is
	map of all types of data stored in store. Each type contains vector of two elements read and
	write fn. Read or Write fn should be used to retrieve data from particular store.
	Read fn: f(image-metadata) -> bytes
	Write fn: f(image-metadata raw original preview thumbnail-square) -> void"
	[]
	; todo should return stores from mongodb and transform them to functions

	{
		:default-store 
			(let [store-path "/Users/vanja/photo-db"]
				{
					:all [
						; read fn / no read function for all
						nil
						; write fn
						(fn [image-metadata raw original preview thumbnail-square]
							(if (not (nil? raw)) 
								(write-bytes-to-store-photodb store-path image-metadata raw :raw))
							(if (not (nil? original)) 
								(write-bytes-to-store-photodb store-path image-metadata original :original))
							(if (not (nil? preview)) 
								(write-bytes-to-store-photodb store-path image-metadata preview :preview))
							(if (not (nil? thumbnail-square)) 
								(write-bytes-to-store-photodb 
									store-path 
									image-metadata 
									thumbnail-square 
									:thumbnail-square)))]
					:preview-and-thumbnail [
						; read fn / no read function for all
						nil
						; write fn
						(fn [image-metadata raw original preview thumbnail-square]
							(if (not (nil? preview)) 
								(write-bytes-to-store-photodb store-path image-metadata preview :preview))
							(if (not (nil? thumbnail-square)) 
								(write-bytes-to-store-photodb 
									store-path 
									image-metadata 
									thumbnail-square 
									:thumbnail-square)))]
					:raw [
						(fn [image-metadata]
							(read-bytes-from-store-photodb store-path image-metadata :raw))
						(fn [image-metadata raw original preview thumbnail-square]
							(if (not (nil? raw)) 
								(write-bytes-to-store-photodb store-path image-metadata raw :raw)))]
					:original [
						(fn [image-metadata]
							(read-bytes-from-store-photodb store-path image-metadata :original))
						(fn [image-metadata raw original preview thumbnail-square]
							(write-bytes-to-store-photodb store-path image-metadata original :original))]
					:preview [
						(fn [image-metadata]
							(read-bytes-from-store-photodb store-path image-metadata :preview))					
						(fn [image-metadata raw original preview thumbnail-square]
							(write-bytes-to-store-photodb store-path image-metadata preview :preview))]
					:thumbnail-square [
						(fn [image-metadata]
							(read-bytes-from-store-photodb store-path image-metadata :thumbnail-square))
						(fn [image-metadata raw original preview thumbnail-square]
							(write-bytes-to-store-photodb 
								store-path 
								image-metadata 
								thumbnail-square 
								:thumbnail-square))]})})


