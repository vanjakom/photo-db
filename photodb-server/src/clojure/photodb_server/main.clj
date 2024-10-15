(ns photodb-server.main
  (:require
    photodb-server.http-server
    ; require of executor will start backend thread
    photodb-server.executor))

(defn -main []
	(println "Starting photodb-server")
	(photodb-server.http-server/start-server))
