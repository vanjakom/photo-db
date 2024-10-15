(ns photodb-server.executor
  (:use
    [clojure.core.async :only (chan thread go <! >! <!! >!! close!)])
  (:require
    [clj-common.logging :as logging]
    [clojure-repl.logging.event :as event]))

(defonce db
	(let [connection (monger.core/connect {:host "localhost" :port 27017})]
		(monger.core/get-db connection "photodb")))

(declare backend-channel)
(declare generate-backend-request-id)
(declare make-backend-request)
(declare mongodb-report-request)

; fn-on-response function to call on response
; fn-on-response [response]
(defn async-backend-request [process-fn context]
	(let [backend-request (make-backend-request process-fn context)]
		(mongodb-report-request backend-request)
		;(event/report "async backend request submit" (stringify-backend-request envelope))
		(go
			(>! backend-channel backend-request))))


			; (let [envelope-done (change-status-backend-request envelope :done)]
			; 	(monger.collection/update
			; 		db
			; 		"backend_queue"
			; 		{:_id (get envelope :_id)} (stringify-backend-request envelope-done))
			; 	(event/report "backend request complete" (stringify-backend-request envelope))))))




(defn- stringify-backend-request [backend-request]
	(assoc backend-request :process-fn (str (:process-fn backend-request))))

(defn- change-status-backend-request [backend-request new-status]
	(assoc backend-request :status new-status))

(defn- make-backend-request [process-fn context]
	{
		:_id (generate-backend-request-id)
		:status :pending
		:process-fn process-fn
		:context context})

(defn- mongodb-report-request [backend-request]
	(monger.collection/insert
		db
		"backend_queue"
		(stringify-backend-request backend-request)))

(defn- mongodb-change-status [backend-request status]
	(monger.collection/update
		db
		"backend_queue"
		{:_id (get backend-request :_id)}
		(stringify-backend-request (assoc backend-request :status status))))

; todo unbuffered ???
(def backend-channel (chan 1000))

(defn- generate-backend-request-id []
	(str (System/currentTimeMillis) "-" (System/nanoTime)))

(thread
	(do
		(.setName (Thread/currentThread) "BackendRequestThread")
		(while true
			(do
				(let [backend-request (<!! backend-channel)]
					(mongodb-change-status backend-request :running)
					(let [
							process-fn (get backend-request :process-fn)
							request (get backend-request :context)]
						(try
              (logging/report backend-request)
							(process-fn request)
							(mongodb-change-status backend-request :done)
							(catch Throwable t
								; todo log throwable
								(.printStackTrace t)
								(mongodb-change-status backend-request :failed)))))))))

