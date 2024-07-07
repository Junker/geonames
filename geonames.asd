(defsystem "geonames"
  :version "0.1.0"
  :author "Dmitrii Kosenkov"
  :license "MIT"
  :depends-on ("uiop" "dexador" "jonathan" "quri" "kebab")
  :components ((:file "package")
               (:file "geonames")))
