(define (make-abyss-preview base-path effect-path output-path)
  (let* ((image (car (gimp-file-load RUN-NONINTERACTIVE base-path)))
         (effect-layer (car (gimp-file-load-layer RUN-NONINTERACTIVE image effect-path))))
    (gimp-image-insert-layer image effect-layer -1 0)
    ; The effect file is a cyan mask on black. Shift it to gold and use screen
    ; blending so only its textured highlight is drawn over the normal curve.
    (gimp-drawable-hue-saturation effect-layer 0 -135 0 0 0)
    (gimp-layer-set-mode effect-layer LAYER-MODE-SCREEN)
    (gimp-layer-set-opacity effect-layer 55)
    (gimp-image-merge-visible-layers image CLIP-TO-IMAGE)
    (export-png image output-path)
    (gimp-image-delete image)))

(define (export-abyss-line-part source-path output-path crop-x crop-y crop-size target-size inner-radius outer-radius)
  (let* ((image (car (gimp-file-load RUN-NONINTERACTIVE source-path)))
         (layer (vector-ref (car (gimp-image-get-layers image)) 0))
         (image-width (car (gimp-drawable-get-width layer)))
         (image-height (car (gimp-drawable-get-height layer))))
    (gimp-layer-add-alpha layer)
    (if (> outer-radius 0)
      (begin
        ; Each curve is a quarter of a circle centred on the bottom-right corner.
        ; Keep only the band containing this orbit before cropping the square.
        (gimp-image-select-ellipse image CHANNEL-OP-REPLACE
          (- image-width outer-radius) (- image-height outer-radius)
          (* outer-radius 2) (* outer-radius 2))
        (gimp-image-select-ellipse image CHANNEL-OP-SUBTRACT
          (- image-width inner-radius) (- image-height inner-radius)
          (* inner-radius 2) (* inner-radius 2))
        (gimp-selection-invert image)
        (gimp-drawable-edit-clear layer)
        (gimp-selection-none image)))
    (gimp-image-crop image crop-size crop-size crop-x crop-y)
    (gimp-image-scale image target-size target-size)
    (export-png image output-path)
    (gimp-image-delete image)))

(define (extract-abyss-lines source-path temporary-directory output-directory state active)
  (let* ((line-height 60)
         (line-image (car (gimp-file-load RUN-NONINTERACTIVE source-path)))
         (line-layer (vector-ref (car (gimp-image-get-layers line-image)) 0))
         (image-size (car (gimp-drawable-get-width line-layer)))
         (line-path (string-append output-directory "abyss-line-connector-" state ".png"))
         (radii '(82 164 334 489 658 839))
         (inner '(40 123 292 411 573 748))
         (outer '(123 207 411 573 748 958))
         (normal-sizes '(33 64 130 191 256 322))
         (active-sizes '(39 70 136 197 262 329))
         (sizes (if (= active 1) active-sizes normal-sizes)))
    ; The straight connector is the strip across the top of the source image.
    (gimp-layer-add-alpha line-layer)
    (gimp-image-crop line-image image-size line-height 0 10)
    (gimp-image-scale line-image 368 13)
    (export-png line-image line-path)
    (gimp-image-delete line-image)

    (let loop ((orbit 1) (radius-list radii) (inner-list inner) (outer-list outer) (size-list sizes))
      (if (not (null? radius-list))
        (let* ((radius (car radius-list))
               (target-size (car size-list))
               ; PoB renders the source art at 38.35% of its game size.
               (crop-size (inexact->exact (round (/ target-size 0.3835))))
               (output-path (string-append temporary-directory "abyss-orbit" (number->string orbit) "-" state ".png")))
          (export-abyss-line-part source-path output-path
            (- image-size crop-size) (- image-size crop-size) crop-size target-size
            (car inner-list) (car outer-list))
          (loop (+ orbit 1) (cdr radius-list) (cdr inner-list) (cdr outer-list) (cdr size-list)))))))
