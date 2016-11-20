(ns photodb-server.http-server)

(require 'ring.adapter.jetty)
(require 'ring.middleware.params)
(require 'ring.middleware.resource)
(require 'ring.middleware.file)
(require 'ring.middleware.json)

(require 'compojure.core)

(use 'clojure-repl.syntax)
(require '[clojure-repl.logging.event :as event])
(require '[clojure-repl.http-server :as http-server])
(require '[clojure-repl.fs.stream	:as fs-stream])

(require '[photodb-server.core :as core])
(require '[photodb-server.render :as render])

(defn api-admin-process-path
	"To be called to import path with images to photodb"
	[request]
	(event/report "api-admin-process-path request" request)
	(let [	params (get request :params)]
		(if-let [	path (get params :path)]
			(if-let [	tags (get params :tags)]
				(do
					(core/process-path-api path tags)
					(http-server/api-response-ok {:status :ok}))
				(http-server/api-response-fail {:status :missing-params}))
			(http-server/api-response-fail {:status :missing-params}))))


; no need for this anymore, api-tag-view returns both :images and :tags
(defn api-tag-explore
	"To be used to retrieve sub tags which could narrow down images list.
	Also returns number of images that are matched with tags list"
	[request]
	(todo "implement this")
	{:status 200 :body "ok"})

(defn api-tag-view
	"To be called to retrieve list of images that are match for given tags.
	Images will be represented by list and sorted in order in which should
	be presented to user"
	[request]
	(event/report "tag-view" request)
	(let [params (get request :params)]
		(if-let [tags (get params :tags)]
			(if-let [response (core/tag-view-api tags)]
				(http-server/api-response-ok response)
				(http-server/api-response-fail {:status :no-images}))
			(http-server/api-response-fail {:status :missing-params}))))

(defn api-tag-list
	"Returns list of all possible tags. To be used on apps to create initial list"
	[request]
	(event/report "tag-list" request)
	(if-let [tags (core/tag-list-api)]
		(http-server/api-response-ok {:tags (get tags :tags-name)})
		(http-server/api-response-fail {:status :no-tags})))

(defn api-image-metadata
	"Returns image metadata for given image id"
	[request]
	(event/report "image-metadata" request)
	(let [params (get request :params)]
		(if-let [id (get params :id)]
			(if-let [image-metadata (get (core/image-metadata-api id) :metadata)]
				(http-server/api-response-ok {
					:id (get image-metadata :id)
					:tags (get image-metadata :tags)})
				(http-server/api-response-fail {:status :no-metadata}))
			(http-server/api-response-fail {:status :missing-params}))))

(defn api-image-update-tags
	"Per given image id updates tags list"
	[request]
	(event/report "image-update-tags" request)
	(let [params (get request :params)]
		(if-let [id (get params :id)]
			(if-let [tags (get params :tags)]
				(if-let [image-metadata (get (core/image-update-tags-api id tags) :metadata)]
					(http-server/api-response-ok {
						:id (get image-metadata :id)
						:tags (get image-metadata :tags)})
					(http-server/api-response-fail {:status :unable-to-update}))
				(http-server/api-response-fail {:status :missing-params}))
			(http-server/api-response-fail {:status :missing-params}))))


(defn render-tag-explore [request]
	(todo "implement this")
	{:body "ok"})

(defn render-tag-view
  "Returns html render of images for given tags"
  [request]
  (event/report "render-tag-view" request)
  (let [params (:params request)]
    (if-let [tags-string (:tags params)]
      (let [tags (clojure.string/split tags-string #";")]
        (if-let [image-type (:type params)]
          (with-open [output-stream (new java.io.ByteArrayOutputStream)]
            (render/render-images-html tags image-type output-stream)
            (let [input-stream (fs-stream/byte-input-stream-from-output-stream output-stream)]
              (http-server/render-response-ok
                "text/html"
                input-stream)))
          (http-server/api-response-fail {:status :missing-params})))
      (http-server/api-response-fail {:status :missing-params}))))


	(todo "implement this")
	{:body "ok"})

(defn render-photo
	"To be called to retrieve image with given id and type"
	[request]
	(event/report "render-photo" request)
	(let [params (get request :params)]
		(if-let [id (get params :id)]
			(if-let [type (keyword (get params :type))]
				(if-let [image-bytes (core/render-image-api id type)]
					(http-server/render-response-ok "image/jpeg" (fs-stream/byte-array-to-stream image-bytes))
					(http-server/render-response-fail))
				(http-server/render-response-fail))
			(http-server/render-response-fail))))

(def api-handler
	(compojure.core/routes
		(compojure.core/POST "/api/admin/process-path" _ api-admin-process-path)
		(compojure.core/POST "/api/tag/explore" _ api-tag-explore)
		(compojure.core/POST "/api/tag/view" _ api-tag-view)
		(compojure.core/POST "/api/tag/list" _ api-tag-list)
		(compojure.core/POST "/api/image/metadata" _ api-image-metadata)
		(compojure.core/POST "/api/image/update-tags" _ api-image-update-tags)))

(def render-handler
	(compojure.core/routes
		(compojure.core/GET "/render/tag/explore" _ render-tag-explore)
		(compojure.core/GET "/render/tag/view" _ render-tag-view)
		(compojure.core/GET "/render/photo" _ render-photo)
		(compojure.core/POST "/render/photo" _
			(ring.middleware.json/wrap-json-params
						(ring.middleware.keyword-params/wrap-keyword-params render-photo)))))


(defonce server-handle (ref nil))

(defn start-server []
	(let [new-server-handle (http-server/start-server 8988 #'api-handler #'render-handler)]
		(dosync (ref-set server-handle new-server-handle))))

(defn stop-server []
	(http-server/stop-server (deref server-handle)))


