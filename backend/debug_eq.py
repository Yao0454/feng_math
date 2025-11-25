import sys
import typing

# --- Monkey Patch Start ---
if sys.version_info >= (3, 12):
    from types import ModuleType
    if "typing.io" not in sys.modules:
        typing_io = ModuleType("typing.io")
        typing_io.TextIO = typing.TextIO
        typing_io.BinaryIO = typing.BinaryIO
        sys.modules["typing.io"] = typing_io
    if "typing.re" not in sys.modules:
        typing_re = ModuleType("typing.re")
        typing_re.Match = typing.Match
        typing_re.Pattern = typing.Pattern
        sys.modules["typing.re"] = typing_re
# --- Monkey Patch End ---

from latex2sympy2 import latex2sympy
from sympy import Eq

latex_str = "x^2 - 5x + 6"
expr = latex2sympy(latex_str)
print(f"Input: {latex_str}")
print(f"Type: {type(expr)}")
print(f"Expr: {expr}")

latex_str = "0"
expr = latex2sympy(latex_str)
print(f"Input: {latex_str}")
print(f"Type: {type(expr)}")
print(f"Expr: {expr}")


