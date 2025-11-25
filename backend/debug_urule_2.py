
from sympy import symbols, exp, sin, cos, Integral
from sympy.integrals.manualintegrate import integral_steps, URule

x = symbols('x')
expr = cos(x) * exp(sin(x))
rule = integral_steps(expr, x)

def find_urule(r):
    if isinstance(r, URule):
        return r
    if hasattr(r, 'substep'):
        return find_urule(r.substep)
    if hasattr(r, 'substeps'):
        for s in r.substeps:
            res = find_urule(s)
            if res: return res
    return None

urule = find_urule(rule)
if urule:
    print("Attributes of URule:")
    for attr in dir(urule):
        if not attr.startswith('_'):
            print(f"{attr}: {getattr(urule, attr)}")
else:
    print("URule not found.")
