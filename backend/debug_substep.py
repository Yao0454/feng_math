
from sympy import symbols, exp, Integral
from sympy.integrals.manualintegrate import integral_steps

x = symbols('x')
expr = x * exp(x**2)
rule = integral_steps(expr, x)
print(f"Rule: {rule}")
print(f"Type: {type(rule)}")
