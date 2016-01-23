(ns photodb-server.io)

(defn direct-buffer-allocate [num-bytes]
	(java.nio.ByteBuffer/allocateDirect num-bytes))

(defn direct-buffer-reset [buffer-handle]
	(.clear buffer-handle))

(defn load-image-into-buffer [buffer-handle image-path]
	)

