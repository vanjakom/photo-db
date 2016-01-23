(ns tags-server.core)

(defonce storage-id (ref {}))
(defonce storage-tag (ref {}))

(defn- generate-id [tags]
	; todo 
	; make unique for high request rate
	(str "id-" (System/currentTimeMillis)))

(defn- match-ids [tags]
	(reduce 
		(fn [state tag-ids]
			(clojure.set/intersection (if (nil? state) tag-ids state) tag-ids))
		nil
		(map (fn [tag] (get (get (deref storage-tag) tag) :ids)) tags)))

(defn- find-possible-tags [ids]
	(reduce 
		(fn [state id]
			(let [id-tags (get (deref storage-id) id)]
				(clojure.set/union (if (nil? state) id-tags state) id-tags)))
		nil
		ids))

(defn query [tags]
	(let [matching-ids (match-ids tags)]
		(let [possible-tags (clojure.set/difference (find-possible-tags matching-ids) (into #{} tags))]
			{
				:ids matching-ids
				:tags (if (nil? possible-tags) #{} possible-tags)})))

(defn- add-id-to-tag [storage-tag tag id]
	(let [tag-in-storage (get storage-tag tag)]
		(assoc
			storage-tag
			tag
			(assoc tag-in-storage 
				:ids (conj (get tag-in-storage :ids #{}) id)
				:count (+ (get tag-in-storage :count 0) 1)))))

(defn- remove-id-from-tag [storage-tag tag id]
	(let [tag-in-storage (get storage-tag tag)]
		(assoc
			storage-tag
			tag
			(assoc tag-in-storage 
				:ids (disj (get tag-in-storage :ids #{}) id)
				:count (- (get tag-in-storage :count 0) 1)))))

(defn add-id [tags]
	(let [id (generate-id tags)]
		(dosync 
			(alter storage-id assoc id (into #{} tags))
			(doseq [tag tags]
				(alter storage-tag add-id-to-tag tag id)))
		id))

(defn remove-id [id]
	(dosync 
		(let [tags (get (deref storage-id) id)]
			(alter storage-id dissoc id)
			(doseq [tag tags]
				(alter storage-tag remove-id-from-tag tag id)))))

; OLD IMPLEMENTATION

(comment

; key: tag string
; value:
;	:tags #{string}
;	:ids #{string}
(defonce storage-lookup (ref {}))
(defonce storage (ref {}))

; query storage for given tags
; returns map
; :tags: [string]
; :ids: [string]
(defn query [tags]
	(reduce
		(fn [result tag-in-storage]
			{
				:tags (clojure.set/intersection (get result :tags) (get tag-in-storage :tags))
				:ids (clojure.set/intersection (get result :ids) (get tag-in-storage :ids))})
		{}
		(map (fn [tag] (get storage-lookup tag)) tags)))



(defn- add-id-to-tag [storage-lookup tag id]
	(let [tag-in-storage (get storage-lookup tag {})]
		(assoc 
			storage-lookup 
			tag 
			(assoc 
				tag-in-storage
				:ids
				(conj (get tag-in-storage :ids #{}) id)))))

(defn- add-tags-to-tag [storage-lookup tag tags]
	(let [tag-in-storage (get storage-lookup tag {})]
		(assoc 
			storage-lookup 
			tag 
			(assoc 
				tag-in-storage
				:tags
				(into (get tag-in-storage :tags #{}) tags)))))

(defn- remove-id-from-tag [storage-lookup tag id]
	(let [tag-in-storage (get storage-lookup tag {})]
		(assoc 
			storage-lookup 
			tag 
			(assoc 
				tag-in-storage
				:ids
				(disj (get tag-in-storage :ids #{}) id)))))

; creates new id which returns and adds it to storage
; tags: [string]
; returns id: string
(defn add-id [tags]
	(let [id (generate-id tags)]
		(dosync 
			(doseq [tag tags]
				(alter storage-lookup add-id-to-tag tag id)
				(alter storage-lookup add-tags-to-tag tag (disj tags tag)))
			(alter storage assoc id (into #{} tags)))))

; removes id form storage
; returns nothing
(defn remove-id [id]
	(let [tags (get storage id)]
		(dosync
			(doseq [tag tags]
				(alter storage-lookup remove-id-from-tag tag id))
			(alter storage dissoc id))))

)