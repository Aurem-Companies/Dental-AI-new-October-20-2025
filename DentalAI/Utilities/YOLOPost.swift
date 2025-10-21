import CoreGraphics

/// Candidate produced from raw YOLO outputs (cx,cy,w,h,obj, class scores)
struct YOLOCandidate {
    var cx: Float, cy: Float, w: Float, h: Float
    var obj: Float
    var scores: [Float] // per-class AFTER sigmoid
    var classIndex: Int { scores.indices.max(by: { scores[$0] < scores[$1] }) ?? 0 }
    var classScore: Float { scores[classIndex] }
    var conf: Float { obj * classScore }
}

enum YOLOPost {
    @inline(__always) static func sig(_ x: Float) -> Float { 1 / (1 + exp(-x)) }

    @inline(__always) static func toCGRect(cx: Float, cy: Float, w: Float, h: Float) -> CGRect {
        let x = CGFloat(cx - w / 2)
        let y = CGFloat(cy - h / 2)
        return CGRect(x: x, y: y, width: CGFloat(w), height: CGFloat(h))
    }

    static func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let inter = a.intersection(b)
        if inter.isNull { return 0 }
        let interA = Float(inter.width * inter.height)
        if interA <= 0 { return 0 }
        let union = Float(a.width * a.height + b.width * b.height) - interA
        return interA / max(1e-6, union)
    }

    static func nms(rects: [CGRect], scores: [Float], iouThresh: Float, limit: Int) -> [Int] {
        let order = scores.enumerated().sorted { $0.element > $1.element }.map { $0.offset }
        var keep: [Int] = []
        var suppressed = [Bool](repeating: false, count: rects.count)
        for i in order {
            if suppressed[i] { continue }
            keep.append(i)
            if keep.count >= limit { break }
            for j in order where j > i && !suppressed[j] {
                if iou(rects[i], rects[j]) >= iouThresh { suppressed[j] = true }
            }
        }
        return keep
    }

    /// Filter <minConfidence>, then greedy NMS
    static func postprocess(cands: [YOLOCandidate], params: DetectionParams) -> [YOLOCandidate] {
        let filtered = cands.filter { $0.conf >= params.minConfidence }
        if filtered.isEmpty { return [] }
        let rects = filtered.map { toCGRect(cx: $0.cx, cy: $0.cy, w: $0.w, h: $0.h) }
        let scores = filtered.map { $0.conf }
        let keepIdx = nms(rects: rects, scores: scores, iouThresh: params.nmsIoU, limit: params.maxDetections)
        return keepIdx.map { filtered[$0] }
    }
}
