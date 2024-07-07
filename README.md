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

(geonames:find-nearby-postal-codes :latitude 47.3 :longitude 9 :style :full)
(geonames:postal-code-country-info)
(geonames:find-nearby-postal-codes :postal-code 9011)
(geonames:astergdem 47.3 9)
(geonames:postal-code-country-info)
;; etc
```
