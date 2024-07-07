(defpackage geonames
  (:use #:cl)
  (:import-from #:uiop
                #:strcat
                #:string-prefix-p)
  (:export #:*username*
           #:postal-code-search
           #:postal-code-lookup
           #:find-nearby-postal-codes
           #:postal-code-country-info
           #:find-nearby-place-name
           #:find-nearby
           #:extended-find-nearby
           #:country-info
           #:country-code
           #:country-subdivision
           #:srtm1
           #:srtm3
           #:astergdem
           #:gtopo30
           #:timezone))
