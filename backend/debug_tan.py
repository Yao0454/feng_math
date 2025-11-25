
from sympy import symbols, tan, Integral
from sympy.integrals.manualintegrate import integral_steps

x = symbols('x')
expr = tan(x)
rule = integral_steps(expr, x)
print(f"Rule: {rule}")
print(f"Type: {type(rule)}")
