"""Import native R.415 hatch boundaries from locally exported ADSCivil DXFs.

Usage: python scripts/import_r415_vectors.py R.415a.dxf R.415b.dxf
Requires ezdxf. Original installation drawings are read only; export copies first.
The XML retains CAD bulges and hatch island roles, without raster tracing.
"""
import argparse
import hashlib
import math
from pathlib import Path
import xml.etree.ElementTree as ET

import ezdxf


ROOT = Path(__file__).resolve().parents[1]


def native_sign(path, code):
    drawing = ezdxf.readfile(path)
    low, high = drawing.header["$EXTMIN"], drawing.header["$EXTMAX"]
    height = high[1] - low[1]
    scale = 1.8 / height
    cx, cy = (low[0] + high[0]) / 2, (low[1] + high[1]) / 2
    sign = ET.Element("sign", code=code, width=f"{(high[0]-low[0])*scale:.9f}",
                      height="1.8", frame="source", provider="ADSCivil TrafficSignal",
                      sourceDrawing=f"{code}.dwg", sourceDxfSha256=hashlib.sha256(Path(path).read_bytes()).hexdigest())
    hatches = [e for e in drawing.modelspace() if e.dxftype() == "HATCH" and e.dxf.color in (7, 1)]
    # The cancellation band must cover all vehicle icons.
    hatches.sort(key=lambda e: e.dxf.color == 1)
    for hatch in hatches:
        shape = ET.SubElement(sign, "shape", color=str(hatch.dxf.color), sourceHandle=hatch.dxf.handle)
        for boundary in hatch.paths:
            if hasattr(boundary, "vertices"):
                vertices = boundary.vertices
            else:
                if not all(type(edge).__name__ == "LineEdge" for edge in boundary.edges):
                    raise ValueError("Unexpected non-polyline curve in hatch " + hatch.dxf.handle)
                vertices = [(edge.start.x, edge.start.y, 0) for edge in boundary.edges]
            if len(vertices) < 2:
                raise ValueError("Empty hatch boundary")
            loop = ET.SubElement(shape, "loop", role="outer" if boundary.path_type_flags & 1 else "hole")
            loop.text = ";".join(f"{(x-cx)*scale:.9f},{(y-cy)*scale+1.5:.9f},{bulge:.15g}" for x, y, bulge in vertices)
    return sign


def svg(sign):
    width = float(sign.get("width"))
    scale = 900 / width
    height = 1.8 * scale
    result = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 {height:.9f}">',
              '<title>R.415a native CAD boundaries from ADSCivil</title>',
              f'<rect width="900" height="{height:.9f}" fill="#0076be"/>']
    for shape in sign.findall("shape"):
        commands = []
        for loop in shape.findall("loop"):
            vertices = [[float(v) for v in p.split(",")] for p in loop.text.split(";")]
            for i, a in enumerate(vertices):
                b = vertices[(i+1) % len(vertices)]
                x, y = (a[0] + width/2) * scale, (2.4-a[1]) * scale
                bx, by = (b[0] + width/2) * scale, (2.4-b[1]) * scale
                if i == 0:
                    commands.append(f"M {x:.9f},{y:.9f}")
                bulge = a[2]
                if abs(bulge) < 1e-12:
                    commands.append(f"L {bx:.9f},{by:.9f}")
                else:
                    radius = math.hypot(bx-x, by-y) * (1+bulge*bulge) / (4*abs(bulge))
                    commands.append(f"A {radius:.9f},{radius:.9f} 0 {int(abs(bulge)>1)} {int(bulge<0)} {bx:.9f},{by:.9f}")
            commands.append("Z")
        ink = "#ffffff" if shape.get("color") == "7" else "#ff0000"
        result.append(f'<path fill="{ink}" fill-rule="evenodd" d="{" ".join(commands)}"/>')
    return "\n".join(result + ["</svg>\n"])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("r415a", type=Path)
    parser.add_argument("r415b", type=Path)
    args = parser.parse_args()
    target = ROOT / "assets/sign-vectors/qcvn-corrections.xml"
    tree = ET.parse(target)
    root = tree.getroot()
    for old in list(root):
        if old.get("code") in ("R.415a", "R.415b"):
            root.remove(old)
    signs = [native_sign(path, code) for path, code in [(args.r415a, "R.415a"), (args.r415b, "R.415b")]]
    root.extend(signs)
    root.set("cleanup", root.get("cleanup", "") + "; 0.6.31: R.415 native ADSCivil CAD hatch boundaries, original circular bulges and island roles")
    root.set("r415Source", "Local ADSCivil NW 2026 For Autocad/TrafficSignal/R.415a.dwg and R.415b.dwg; read-only DXF exports")
    ET.indent(tree, space="  ")
    tree.write(target, encoding="utf-8", xml_declaration=True)
    (ROOT / "assets/sign-vectors/r415-pictograms.svg").write_text(svg(signs[0]), encoding="utf-8")
    for sign in signs:
        print(sign.get("code"), "shapes", len(sign.findall("shape")), "loops", len(sign.findall("shape/loop")))


if __name__ == "__main__":
    main()
