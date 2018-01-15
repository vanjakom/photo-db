(ns photodb-server.render)

(require '[photodb-server.manage :as manage])

(defn render-images-html
  "Renders html with all images that match given set of tags. image-type, type of images.
  output-stream to which html will be written."
  [tags image-type output-stream]
  (let [images (manage/images-find tags)]
    (with-open [album-writer (clojure.java.io/writer output-stream)]
      (.write album-writer "<html>\n\t<head>\n\t</head>\n\t<body align='center' style='background-color:black'>\n")
      (.write album-writer "</br></br></br></br>")
      (doseq [image images]
        (let [image-id (:id image)
              description (or (:description image) "unknown")
              image-path (str "/render/photo?id=" image-id "&type=" image-type)]
          (.write album-writer (str
                                 "\t\t<img src='" image-path
                                 "' style='max-width:1800px;max-height:1100px;width:auto;height:auto;'>"
                                 "</br>"
                                 "</br>"
                                 "<p style='color:white;padding:0;margin:0'>" description "</p>"
                                 "<p style='color:white;padding:0;margin:0'>" image-id "</p></br>"
                                 "</br></br></br></br></br>\n"))))
      (.write album-writer "\t</body>\n</html>"))))
