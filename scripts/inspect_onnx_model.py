import sys, json
import onnx
from onnx import numpy_helper

PATH = "DentalAI/Resources/Models/dental_model.onnx"

def is_probably_yolo(onnx_model):
    # Heuristics that cover YOLOv5/YOLOv8-style exports and many forks:
    # - Output tensor last-dim >= 5 (cx, cy, w, h, obj) + classes
    # - Node names/op types containing yolo-ish terms
    # - Single output shaped [1, N, D] or multiple heads with concatenation
    out_shapes = []
    for o in onnx_model.graph.output:
        shp = []
        if o.type.tensor_type.HasField("shape"):
            for d in o.type.tensor_type.shape.dim:
                if d.HasField("dim_value"):
                    shp.append(int(d.dim_value))
                else:
                    shp.append(None)
            out_shapes.append(shp)

    last_dims = [s[-1] for s in out_shapes if s and isinstance(s[-1], int)]
    big_last_dim = any((isinstance(d, int) and d >= 5) for d in last_dims)

    node_names = " ".join(n.name.lower() for n in onnx_model.graph.node)
    node_ops   = " ".join(n.op_type.lower() for n in onnx_model.graph.node)
    yolo_terms = ["yolo", "detect", "focus", "sigmoid", "nms", "grid", "anchor"]
    has_terms  = any(t in node_names or t in node_ops for t in yolo_terms)

    # Also check if outputs look like [1, N, D] with large N
    yoloish_shape = False
    for s in out_shapes:
        if len(s) == 3 and s[0] in (1, None) and isinstance(s[1], int) and s[1] >= 100 and isinstance(s[-1], int) and s[-1] >= 5:
            yoloish_shape = True

    return big_last_dim and (has_terms or yoloish_shape), out_shapes

def main():
    try:
        m = onnx.load(PATH)
    except Exception as e:
        print(json.dumps({"ok": False, "error": f"Failed to load ONNX: {e}"}))
        sys.exit(1)

    yolo, shapes = is_probably_yolo(m)
    inputs = [i.name for i in m.graph.input]
    outputs = [o.name for o in m.graph.output]
    ops = list({n.op_type for n in m.graph.node})

    print(json.dumps({
        "ok": True,
        "path": PATH,
        "inputs": inputs,
        "outputs": outputs,
        "output_shapes_inferred": shapes,
        "unique_ops_count": len(ops),
        "is_probably_yolo": yolo
    }, indent=2))

if __name__ == "__main__":
    main()
