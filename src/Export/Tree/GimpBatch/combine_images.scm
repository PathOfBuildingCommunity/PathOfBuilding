(define (export-png image output-path)
  ; Export timestamps make otherwise identical PNGs change on every run.
  (file-png-export
    #:run-mode RUN-NONINTERACTIVE
    #:image image
    #:file output-path
    #:options -1
    #:interlaced FALSE
    #:compression 9
    #:bkgd TRUE
    #:offs FALSE
    #:phys TRUE
    #:time FALSE
    #:save-transparent TRUE
    #:optimize-palette FALSE
    #:format "auto"))

(define (combine-images-into-sprite-sheet output-path width height saturation entries)
  (let* ((sprite-sheet (car (gimp-image-new width height RGB)))
         (background (car (gimp-layer-new sprite-sheet "Background" width height RGBA-IMAGE 100 LAYER-MODE-NORMAL))))
    (gimp-image-insert-layer sprite-sheet background 0 0)

    (for-each
      (lambda (entry)
        (let* ((file (list-ref entry 0))
               (source-x (list-ref entry 1))
               (source-y (list-ref entry 2))
               (source-width (list-ref entry 3))
               (source-height (list-ref entry 4))
               (target-x (list-ref entry 5))
               (target-y (list-ref entry 6))
               (target-width (list-ref entry 7))
               (target-height (list-ref entry 8))
               (layer (car (gimp-file-load-layer RUN-NONINTERACTIVE sprite-sheet file))))
          (gimp-image-insert-layer sprite-sheet layer -1 0)
          ; UIImages share a texture, so crop before scaling and placing the layer.
          (gimp-layer-resize layer source-width source-height (- source-x) (- source-y))
          (gimp-layer-scale layer target-width target-height TRUE)
          (if (< saturation 100)
            (gimp-drawable-hue-saturation layer 0 0 0 (- saturation 100) 0))
          (gimp-layer-set-offsets layer target-x target-y)))
      entries)

    (gimp-image-merge-visible-layers sprite-sheet CLIP-TO-IMAGE)
    (export-png sprite-sheet output-path)
    (gimp-image-delete sprite-sheet)))
