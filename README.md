# Geonames

GeoNames API Client for Common Lisp

## Warning

This software is still BETA quality. The APIs will be likely to change.

## Installation

This system can be installed from [UltraLisp](https://ultralisp.org/) like this:

```common-lisp
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload "geonames")
```

## Usage

```common-lisp
(setf geonames:*username* "MY-API-USERNAME")

(defvar *lat* 47.3)
(defvar *lng* 9)
(geonames:find-nearby-postal-codes :latitude *lat* :longitude *lng* :style :full)
(geonames:postal-code-country-info)
(geonames:find-nearby-postal-codes :postal-code 9011)
(geonames:astergdem *lat* *lng*)
(geonames:country-code *lat* *lng*)
(geonames:timezone *lat* *lng*)
(geonames:country-info :country "DE" :language "FR")
;; etc
```
