(ns photodb-server.setup)

; should be used to setup inital db env

(require 'monger.core)
(require '[monger.collection :as mongo])

(defn setup []
	(let [	connection (monger.core/connect {:host "localhost" :port 27017})
			db (monger.core/get-db connection "photodb")]

		(mongo/drop db "stores")
		(mongo/drop db "tags")
		(mongo/drop db "images")
		(mongo/drop db "backend_queue")

		; not used currently
		(mongo/insert db "stores" {
			:_id "default-store"
			:id "default-store"
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
					:type "photo-db"}}})

		(mongo/insert db "tags" {
			:_id "#best-2016"
			:id "#best-2016"
			:stores {
				:default-store (list :all)}})


		))

