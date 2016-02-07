(ns photodb-server.manage)

(require 'monger.core)
(require '[monger.collection :as mongo])

(use 'monger.operators)

(defonce ^:private db 
	(let [connection (monger.core/connect {:host "localhost" :port 27017})]
		(monger.core/get-db connection "photodb")))

; todo in future we should be able to change stores and types for tag
(defn tag-create-if-not-exists [name]
	(try 
		(mongo/insert-and-return db "tags" {
			:_id name
			:id name
			:stores '(
				[:default-store '(:all)])})
		(catch com.mongodb.DuplicateKeyException e nil)))

(defn tags-list []
	(mongo/find-maps db "tags"))

(defn tag-get [name]
	(mongo/find-one-as-map db "tags" {:id name}))

(defn image-tags-set 
	"Should be used during image update"
	[image-id tags]
	(mongo/update db "images" {:id image-id} {$set {:tags tags}}))

(defn image-create 
	"Should be used during process image, initial image import"
	[image-metadata]
	(mongo/insert-and-return db "images" image-metadata))

(defn image-get [image-id]
	(mongo/find-one-as-map db "images" {:id image-id}))

(defn images-find [tags]
	(mongo/find-maps db "images" {:tags {$all tags}}))