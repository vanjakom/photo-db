(ns tags-server.notes-sample-app)

(require 'clojure-repl.http-server)

(require 'clojure.pprint)

(require 'tags-server.core)

(defonce storage-note (ref {}))

(defn api-note-add [request]
	(println "api-note-add handler")
	(clojure.pprint/pprint request)
	(let [params (get request :params)]
		(let [	note-name (get params :name)
				note-tags (get params :tags)
				note-body (get params :body)]
			(let [id (tags-server.core/add-id note-tags)]
				(dosync
					(alter 
						storage-note 
						assoc 
						id 
						{
							:id id
							:name note-name
							:body note-body}))
				{:body {:status "ok"}}))))

(defn api-note-get [request]
	(println "api-note-get handler")
	(let [params (get request :params)]
		(let [id (get params :id)]
			{:body (get (deref storage-note) id)})))

(defn api-note-query [request]
	(println "api-note-query handler")
	(let [params (get request :params)]
		(let [tags (get params :tags)]
			{:body (tags-server.core/query tags)})))

(def api-handler
	(compojure.core/routes
		(compojure.core/POST "/api/note/add" _ api-note-add)
		(compojure.core/POST "/api/note/get" _ api-note-get)
		(compojure.core/POST "/api/note/query" _ api-note-query)))

(def render-handler
	{:body "render empty"})

(defonce server-handle (ref nil))

(defn start-server []
	(let [new-server-handle (clojure-repl.http-server/start-server 8989 #'api-handler #'render-handler)]
		(dosync (ref-set server-handle new-server-handle))))

(defn stop-server []
	(clojure-repl.http-server/stop-server (deref server-handle)))

