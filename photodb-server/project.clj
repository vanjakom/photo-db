(defproject photodb-server "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :source-paths ["src/clojure"]
  :java-source-paths ["src/java"]
  :resource-paths ["src/resource"]
  :main photodb-server.main
  :dependencies [
  	 [com.mungolab/clojure-repl 					"0.1.0-SNAPSHOT"]
	   [com.novemberain/monger 					"3.0.1"]
	   [com.drewnoakes/metadata-extractor 			"2.8.1"]])
