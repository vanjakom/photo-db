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


; hachaton 1 handlers
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
			(if-let [images (core/tag-view-api tags)]
				(http-server/api-response-ok {:images images})
				(http-server/api-response-fail {:status :no-images}))
			(http-server/api-response-fail {:status :missing-params}))))

(defn api-tag-list
	"Returns list of all possible tags. To be used on apps to create initial list"
	[request]
	(event/report "tag-list" request)
	(core/tag-list-api))

(defn render-tag-explore [request]
	(todo "implement this")
	{:body "ok"})

(defn render-tag-view [request]
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

; to be used for hackaton 1
(def api-handler
	(compojure.core/routes
		(compojure.core/POST "/api/admin/process-path" _ api-admin-process-path)
		(compojure.core/POST "/api/tag/explore" _ api-tag-explore)
		(compojure.core/POST "/api/tag/view" _ api-tag-view)
		(compojure.core/POST "/api/tag/list" _ api-tag-list)))

(def render-handler
	(compojure.core/routes
		(compojure.core/GET "/render/tag/explore" _ render-tag-explore)
		(compojure.core/GET "/render/tag/view" _ render-tag-view)
		(compojure.core/GET "/render/photo" _ render-photo)))


(defonce server-handle (ref nil))

(defn start-server []
	(let [new-server-handle (http-server/start-server 8988 #'api-handler #'render-handler)]
		(dosync (ref-set server-handle new-server-handle))))

(defn stop-server []
	(http-server/stop-server (deref server-handle)))


; production code + old code

; (comment

; (defonce server-port 8181)

; (defonce server-handle (ref nil))

; )

; (comment
; ; to be used in production
; (defn api-photo-metadata [request]
; 	{:status :ok})

; (defn api-photo-update [request]
; 	{:status :ok})

; (defn api-tag-list [request]
; 	{:status :ok})

; (defn api-tag-metadata [request]
; 	{:status :ok})

; (defn api-tag-update [request]
; 	{:status :ok})
; )

; to be used in production
; (comment
; 	(defn api-handler [request]
; 		(compojure.core/routes
; 			(compojure.core/POST "/api/status" _ (fn [request] {:status :ok}))
; 			(compojure.core/POST "/api/photo/metadata" _ api-photo-metadata)
; 			(compojure.core/POST "/api/photo/update" _ api-photo-update)
; 			(compojure.core/POST "/api/tag/list" _ api-tag-list)
; 			(compojure.core/POST "/api/tag/explore" _ api-tag-explore)
; 			(compojure.core/POST "/api/tag/metadata" _ api-tag-metadata)
; 			(compojure.core/POST "/api/tag/update" _ api-tag-update)))

; 	(defn render-handler [request]
; 		{:body "this should render image"})
; )

; application routes
; / -> GET, static file, index.html
; /web/ -> GET, static file
; /api/ -> POST, json -> json
; /render/ -> GET, byte[]
; delete
; (comment 
; 	(def handler
; 		(compojure.core/routes 
; 				(compojure.core/GET
; 					"/"
; 					_
; 					(fn [request]
; 						(let [new-request (assoc request :path-info "/web/index.html")]
; 							(ring.middleware.resource/resource-request new-request ""))))
; 				(compojure.core/GET
; 					"/web/*"
; 					_
; 					(fn [request]
; 						(ring.middleware.resource/resource-request request "")))
; 				(compojure.core/POST
; 					"/api/*"
; 					_
; 					(ring.middleware.json/wrap-json-response 
; 						(ring.middleware.json/wrap-json-params 
; 							api-handler {:keywords? true})))
; 				(compojure.core/GET
; 					"/render/*"
; 					_
; 					render-handler)))

; 	(declare stop-server)

; 	; send handler as var to enable change of handler in runtime
; 	(defn start-server []
; 		(if (some? @server-handle)
; 			(stop-server))
; 		(let [new-server-handle (ring.adapter.jetty/run-jetty #'handler {:port server-port :join? false})]
; 			(dosync (ref-set server-handle new-server-handle))))

; 	(defn stop-server []
; 		(if (some? @server-handle)
; 			(do
; 				(.stop server-handle)
; 				(dosync (ref-set server-handle nil)))))
; )

