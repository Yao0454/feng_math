
from sympy import symbols, exp, Integral
from sympy.integrals.manualintegrate import integral_steps, URule

x = symbols('x')
expr = x * exp(x**2)
rule = integral_steps(expr, x)

print(f"Rule type: {type(rule)}")
# URule usually appears inside other rules or directly.
# For x*exp(x**2), u=x**2, du=2x dx.
# Let's see if we get URule.

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
    print("URule not found in this example.")
