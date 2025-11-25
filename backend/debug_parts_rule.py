
from sympy import symbols, ln, Integral
from sympy.integrals.manualintegrate import integral_steps, PartsRule

x = symbols('x')
expr = ln(x)
rule = integral_steps(expr, x)

print(f"Rule type: {type(rule)}")
if isinstance(rule, PartsRule):
    print("Attributes of PartsRule:")
    for attr in dir(rule):
        if not attr.startswith('_'):
            print(f"{attr}: {getattr(rule, attr)}")
