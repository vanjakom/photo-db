(ns photodb-server.main)

(require 'photodb-server.http-server)

(defn -main []
	(println "Starting photodb-server")
	(photodb-server.http-server/start-server))