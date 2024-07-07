(in-package #:geonames)

(defparameter *base-url* "http://api.geonames.org/")
(defparameter *username* nil)

;; (defvar *error-codes*
;;   '((10 . "Authorization Exception")
;;     (11 . "record does not exist")
;;     (12 . "other error")
;;     (13 . "database timeout")
;;     (14 . "invalid parameter")
;;     (15 . "no result found")
;;     (16 . "duplicate exception")
;;     (17 . "postal code not found")
;;     (18 . "daily limit of credits exceeded")
;;     (19 . "hourly limit of credits exceeded")
;;     (20 . "weekly limit of credits exceeded")
;;     (21 . "invalid input")
;;     (22 . "server overloaded exception")
;;     (23 . "service not implemented")
;;     (24 . "radius too large")
;;     (27 . "maxRows too large")))

(define-condition geonames-error (simple-error)
  ((code :reader code
         :initarg :code
         :documentation "The error code.")
   (message :reader message
            :initarg :message
            :documentation "Explanation message.")
   (parent-condition :reader parent-condition
                     :initarg :parent-condition
                     :initform nil))
  (:report (lambda (condition stream)
             (format stream "Geonames error ~A: ~A."
                     (code condition) (message condition)))))

(declaim (inline key-normalize))
(defun key-normalize (key)
  (string-upcase (kebab:to-lisp-case key)))

(defun handle-status-response (data &optional parent-condition)
  (let ((status (getf data :status)))
    (error (make-condition 'geonames-error
                           :code (getf status :value)
                           :message (getf status :message)
                           :parent-condition parent-condition))))

(defun api-call (uri params)
  (handler-case (multiple-value-bind (body status headers)
                    (dex:get (strcat *base-url* uri "?"
                                     (quri:url-encode-params (append params
                                                                     (list (cons "username" *username*)))))
                             :keep-alive nil)
                  (declare (ignore status))
                  (let ((data (jojo:parse body :keyword-normalizer #'key-normalize
                                               :normalize-all t)))
                    (cond ((not (string-prefix-p "application/json"
                                                 (gethash "content-type" headers "")))
                           (error "response must be JSON"))
                          ((eq (car data) :status)
                           (handle-status-response data))
                          (t
                           data))))
    (dex:http-request-failed (e)
      (if (string-prefix-p "application/json"
                           (gethash "content-type" (dex:response-headers e) ""))
          (let* ((data (jojo:parse (dex:response-body e)
                                   :keyword-normalizer #'key-normalize
                                   :normalize-all t)))
            (handle-status-response data e))
          (error e)))))


;; ========== PUBLIC

(defun postal-code-search (&key postal-code place-name postal-code-starts-with place-name-starts-with
                             country country-bias is-reduced east west north south
                             (operator :and) (max-rows 10) (style :medium))
  (api-call "postalCodeSearchJSON" (append `(("isReduced" . ,is-reduced)
                                             ("maxRows" . ,max-rows)
                                             ("style" . ,(string style))
                                             ("operator" . ,(string operator)))
                                           (when postal-code `(("postalcode" . ,postal-code)))
                                           (when place-name `(("placename" . ,place-name)))
                                           (when postal-code-starts-with `(("postalcode_startsWith" . ,postal-code-starts-with)))
                                           (when place-name-starts-with `(("placename_startsWith" . ,place-name-starts-with)))
                                           (when country (mapcar (lambda (c) (cons "country" c))
                                                                 (uiop:ensure-list country)))
                                           (when country-bias `(("countryBias" . ,country-bias)))
                                           (when east `(("east" . ,east)
                                                        ("west" . ,west)
                                                        ("north" . ,north)
                                                        ("south" . ,south))))))

(defun postal-code-lookup (postal-code &key country callback (max-rows 20))
  (api-call "postalCodeLookupJSON" (append `(("postalcode" . ,postal-code)
                                             ("maxRows" . ,max-rows))
                                           (when country (mapcar (lambda (c) (cons "country" c))
                                                                 (uiop:ensure-list country)))
                                           (when callback `(("callback" . ,callback))))))

(defun find-nearby-postal-codes (&key postal-code latitude longitude radius country local-country is-reduced
                                   (max-rows 5) (style :medium))
  (assert (or postal-code (and latitude longitude)))
  (api-call "findNearbyPostalCodesJSON" (append `(("isReduced" . ,is-reduced)
                                                  ("maxRows" . ,max-rows)
                                                  ("style" . ,(string style)))
                                                (when postal-code `(("postalcode" . ,postal-code)))
                                                (when latitude `(("lat" . ,latitude)))
                                                (when longitude `(("lng" . ,longitude)))
                                                (when radius `(("radius" . ,radius)))
                                                (when local-country `(("localCountry" . ,local-country)))
                                                (when country (mapcar (lambda (c) (cons "country" c))
                                                                      (uiop:ensure-list country))))))

(defun postal-code-country-info ()
  (api-call "postalCodeCountryInfoJSON" nil))

(defun find-nearby-place-name (latitude longitude &key radius local-country cities language
                                                    (max-rows 10) (style :medium))
  (api-call "findNearbyPlaceNameJSON" (append `(("maxRows" . ,max-rows)
                                                ("style" . ,(string style)))
                                              (when latitude `(("lat" . ,latitude)))
                                              (when longitude `(("lng" . ,longitude)))
                                              (when radius `(("radius" . ,radius)))
                                              (when local-country `(("localCountry" . ,local-country)))
                                              (when cities `(("cities" . ,cities)))
                                              (when language `(("lang" . ,language))))))

(defun find-nearby (latitude longitude &key radius local-country feature-class feature-code
                                         (max-rows 10) (style :medium))
  (api-call "findNearbyJSON" (append `(("lat" . ,latitude)
                                       ("lng" . ,longitude)
                                       ("maxRows" . ,max-rows)
                                       ("style" . ,(string style)))
                                     (when radius `(("radius" . ,radius)))
                                     (when local-country `(("localCountry" . ,local-country)))
                                     (when feature-code (mapcar (lambda (c) (cons "featureCode" c))
                                                                (uiop:ensure-list feature-code)))
                                     (when feature-class `(("featureClass" . ,feature-class))))))

(defun extended-find-nearby (latitude longitude)
  (api-call "extendedFindNearbyJSON" `(("lat" . ,latitude)
                                       ("lng" . ,longitude))))

(defun country-info (&key country language)
  (api-call "countryInfoJSON" (append
                               (when language `(("lang" . ,language)))
                               (when country (mapcar (lambda (c) (cons "country" c))
                                                     (uiop:ensure-list country))))))

(defun country-code (latitude longitude &key radius type language)
  (api-call "countryCodeJSON" (append `(("lat" . ,latitude)
                                        ("lng" . ,longitude))
                                      (when radius `(("radius" . ,radius)))
                                      (when type `(("type" . ,type)))
                                      (when language `(("lang" . ,language))))))

(defun country-subdivision (latitude longitude &key radius level language)
  (api-call "countrySubdivisionJSON" (append `(("lat" . ,latitude)
                                               ("lng" . ,longitude))
                                             (when radius `(("radius" . ,radius)))
                                             (when level `(("level" . ,level)))
                                             (when language `(("lang" . ,language))))))

(defun srtm1 (latitude longitude)
  (api-call "srtm1JSON" `(("lat" . ,latitude)
                          ("lng" . ,longitude))))

(defun srtm3 (latitude longitude)
  (api-call "srtm3JSON" `(("lat" . ,latitude)
                          ("lng" . ,longitude))))

(defun astergdem (latitude longitude)
  (api-call "astergdemJSON" `(("lat" . ,latitude)
                              ("lng" . ,longitude))))

(defun gtopo30 (latitude longitude)
  (api-call "gtopo30JSON" `(("lat" . ,latitude)
                            ("lng" . ,longitude))))

(defun timezone (latitude longitude &key radius date)
  (api-call "timezoneJSON" (append `(("lat" . ,latitude)
                                     ("lng" . ,longitude))
                                   (when radius `(("radius" . ,radius)))
                                   (when date `(("date" . ,date))))))
