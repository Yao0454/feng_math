import sys
import typing
import re

# --- Monkey Patch Start ---
# 修复 antlr4-python3-runtime 在高版本 Python (3.12+) 下的兼容性问题
# 旧版 antlr4 尝试从 'typing.io' 导入，该模块已被移除
if sys.version_info >= (3, 12):
    from types import ModuleType
    
    # 模拟 typing.io
    if "typing.io" not in sys.modules:
        typing_io = ModuleType("typing.io")
        typing_io.TextIO = typing.TextIO
        typing_io.BinaryIO = typing.BinaryIO
        sys.modules["typing.io"] = typing_io

    # 模拟 typing.re (通常也需要)
    if "typing.re" not in sys.modules:
        typing_re = ModuleType("typing.re")
        typing_re.Match = typing.Match
        typing_re.Pattern = typing.Pattern
        sys.modules["typing.re"] = typing_re
# --- Monkey Patch End ---

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from latex2sympy2 import latex2sympy
from sympy import latex, simplify, Eq, solve, Integral, Derivative, Add, Mul, Pow, Symbol, sin, cos, exp, log, Poly
from sympy.integrals.manualintegrate import (
    integral_steps, 
    PartsRule, 
    URule, 
    PowerRule, 
    AddRule, 
    ConstantRule, 
    TrigRule,
    ReciprocalRule,
    ConstantTimesRule,
    AlternativeRule,
    ExpRule,
    RewriteRule,
    DontKnowRule
)
import uvicorn

app = FastAPI()

class MathRequest(BaseModel):
    latex: str

def generate_derivative_steps(expr: Derivative):
    """
    尝试生成求导步骤
    """
    steps = []
    try:
        var = expr.variables[0]
        func = expr.expr
        
        steps.append(r"\text{目标: 对 } " + latex(func) + r" \text{ 关于 } " + latex(var) + r" \text{ 求导}")

        if isinstance(func, Add):
            steps.append(r"\text{应用加法法则: } \frac{d}{dx}(u+v) = \frac{du}{dx} + \frac{dv}{dx}")
            steps.append(r"\quad \Rightarrow " + r" + ".join([r"\frac{d}{dx}(" + latex(arg) + r")" for arg in func.args]))
        
        elif isinstance(func, Mul):
            # 简单的乘法法则展示 (只展示两个项的情况，多项类似)
            if len(func.args) == 2:
                u, v = func.args
                steps.append(r"\text{应用乘法法则: } \frac{d}{dx}(uv) = u'v + uv'")
                steps.append(r"\quad u = " + latex(u) + r", \quad v = " + latex(v))
                steps.append(r"\quad \Rightarrow (" + latex(u.diff(var)) + r") \cdot " + latex(v) + r" + " + latex(u) + r" \cdot (" + latex(v.diff(var)) + r")")
            else:
                steps.append(r"\text{应用乘法法则}")

        elif isinstance(func, Pow):
            base, exponent = func.args
            if exponent.is_constant():
                steps.append(r"\text{应用幂法则/链式法则: } \frac{d}{dx}(u^n) = n u^{n-1} \cdot u'")
                steps.append(r"\quad \Rightarrow " + latex(exponent) + r"(" + latex(base) + r")^{" + latex(exponent - 1) + r"} \cdot \frac{d}{dx}(" + latex(base) + r")")
            else:
                steps.append(r"\text{应用指数求导法则}")

        elif func.func in (sin, cos, exp, log):
             steps.append(r"\text{应用基本函数求导公式}")
             if len(func.args) > 0 and func.args[0] != var:
                 steps.append(r"\text{并应用链式法则}")

    except Exception as e:
        print(f"Derivative step error: {e}")
    return steps

def generate_equation_steps(eq: Eq):
    """
    尝试生成方程求解步骤
    """
    steps = []
    try:
        # 假设是单变量方程
        free_symbols = eq.free_symbols
        if len(free_symbols) == 1:
            x = list(free_symbols)[0]
            lhs = eq.lhs - eq.rhs # 移项使得 rhs = 0
            
            steps.append(r"\text{移项整理得: } " + latex(lhs) + " = 0")
            
            poly = Poly(lhs, x)
            degree = poly.degree()
            
            if degree == 1:
                coeffs = poly.all_coeffs()
                a, b = coeffs[0], coeffs[1]
                steps.append(r"\text{这是一个线性方程 } ax + b = 0")
                steps.append(r"\quad a = " + latex(a) + r", \quad b = " + latex(b))
                steps.append(r"\text{解为: } x = -\frac{b}{a}")
                steps.append(r"\quad \Rightarrow x = " + latex(-b/a))
            
            elif degree == 2:
                coeffs = poly.all_coeffs()
                a, b, c = coeffs[0], coeffs[1], coeffs[2]
                steps.append(r"\text{这是一个一元二次方程 } ax^2 + bx + c = 0")
                steps.append(r"\quad a = " + latex(a) + r", \quad b = " + latex(b) + r", \quad c = " + latex(c))
                steps.append(r"\text{应用求根公式: } x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}")
                delta = b**2 - 4*a*c
                steps.append(r"\quad \Delta = b^2 - 4ac = " + latex(delta))
                if delta >= 0:
                    steps.append(r"\quad x_1 = \frac{" + latex(-b) + r" + \sqrt{" + latex(delta) + r"}}{" + latex(2*a) + r"}")
                    steps.append(r"\quad x_2 = \frac{" + latex(-b) + r" - \sqrt{" + latex(delta) + r"}}{" + latex(2*a) + r"}")
                else:
                    steps.append(r"\text{判别式小于0，无实数解 (或为复数解)}")
            
            else:
                steps.append(r"\text{尝试因式分解或数值解法}")
                
    except Exception as e:
        print(f"Equation step error: {e}")
    return steps

def generate_integral_steps(expr: Integral):
    """
    尝试生成积分步骤
    """
    steps = []
    try:
        var = expr.variables[0]
        integrand = expr.function
        rule = integral_steps(integrand, var)
        
        def parse_rule(r, depth=0):
            res = []
            indent = r"\quad " * depth
            
            if isinstance(r, PartsRule):
                # PartsRule 可能不直接包含 du 和 v，需要计算
                u = r.u
                dv = r.dv
                var = r.variable
                du = u.diff(var)
                v = dv.integrate(var)

                res.append(indent + r"\text{应用分部积分法: } \int u dv = uv - \int v du")
                res.append(indent + r"\quad u = " + latex(u) + r", \quad dv = " + latex(dv))
                res.append(indent + r"\quad du = " + latex(du) + r", \quad v = " + latex(v))
                res.append(indent + r"\quad \Rightarrow " + latex(u * v) + r" - \int " + latex(v * du))
                if r.second_step:
                    res.extend(parse_rule(r.second_step, depth + 1))
            
            elif isinstance(r, URule):
                res.append(indent + r"\text{应用换元法: } u = " + latex(r.u_func))
                # res.append(indent + r"\quad du = " + latex(r.constant * r.u_var) + r" dx") # 近似表达
                if r.substep:
                    res.extend(parse_rule(r.substep, depth + 1))
            
            elif isinstance(r, AlternativeRule):
                # AlternativeRule 包含多种可能的积分路径，我们只展示第一种有效路径
                if r.alternatives:
                    res.extend(parse_rule(r.alternatives[0], depth))
            
            elif isinstance(r, RewriteRule):
                res.append(indent + r"\text{重写被积函数: } \int " + latex(r.rewritten) + r" dx")
                if r.substep:
                    res.extend(parse_rule(r.substep, depth + 1))
            
            elif isinstance(r, DontKnowRule):
                res.append(indent + r"\text{无法找到进一步的积分步骤}")

            elif isinstance(r, AddRule):
                res.append(indent + r"\text{利用线性性质拆分:}")
                for sub in r.substeps:
                    res.extend(parse_rule(sub, depth + 1))
            
            elif isinstance(r, ConstantTimesRule):
                res.append(indent + r"\text{提取常数: } \int c \cdot f(x) dx = c \cdot \int f(x) dx")
                res.append(indent + r"\quad \text{常数: } " + latex(r.constant))
                if r.substep:
                    res.extend(parse_rule(r.substep, depth + 1))

            elif isinstance(r, PowerRule):
                res.append(indent + r"\text{应用幂法则: } \int x^n dx = \frac{x^{n+1}}{n+1}")
            
            elif isinstance(r, ReciprocalRule):
                res.append(indent + r"\text{应用倒数法则: } \int \frac{1}{x} dx = \ln|x|")
            
            elif isinstance(r, ExpRule):
                res.append(indent + r"\text{应用指数法则: } \int e^x dx = e^x")

            elif isinstance(r, TrigRule):
                res.append(indent + r"\text{应用三角函数积分公式}")
                
            elif isinstance(r, ConstantRule):
                res.append(indent + r"\text{常数积分: } \int c dx = cx")
                
            return res

        steps.extend(parse_rule(rule))
    except Exception as e:
        print(f"Step generation error: {e}")
        # steps.append(r"\text{无法生成详细步骤}")
    return steps

@app.post("/solve")
async def solve_math(request: MathRequest):
    """
    接收 LaTeX 字符串，解析为 SymPy 表达式，
    调用 .doit() 进行求解，并返回结果的 LaTeX 字符串。
    """
    try:
        print(f"Received LaTeX: {request.latex}")
        
        # 预处理 LaTeX 字符串
        # 1. 替换 latex2sympy2 可能不支持的间距符号
        fixed_latex = request.latex.replace(r"\:", " ").replace(r"\,", " ")
        # 2. 确保 dx 前面有空格 (可选，视解析器情况而定)
        
        print(f"Processed LaTeX: {fixed_latex}")

        # 1. 解析 LaTeX 为 SymPy 对象
        # latex2sympy2 能够处理积分、导数、极限等符号
        # 预处理：把类似 '{=}' 这样的带大括号等号规范为 '='，以避免分割错误
        fixed_latex = re.sub(r'\{\s*=\s*\}', '=', fixed_latex)

        try:
            # 特殊处理方程：如果包含 '='，手动分割左右两边，避免 latex2sympy 自动求解
            if "=" in fixed_latex:
                parts = fixed_latex.split("=")
                if len(parts) == 2:
                    lhs_latex = parts[0].strip()
                    rhs_latex = parts[1].strip()
                    try:
                        lhs = latex2sympy(lhs_latex)
                        rhs = latex2sympy(rhs_latex)
                        expr = Eq(lhs, rhs)
                    except Exception:
                        # 如果分割解析失败，回退到默认解析
                        expr = latex2sympy(fixed_latex)
                else:
                    expr = latex2sympy(fixed_latex)
            else:
                expr = latex2sympy(fixed_latex)
        except Exception as e:
            print(f"Latex parsing error: {e}")
            import traceback
            traceback.print_exc()
            raise e
        
        print(f"Parsed expression type: {type(expr)}")
        print(f"Parsed expression: {expr}")

        # 2. 判断是否为方程 (Equality)
        steps = []
        steps.append(r"\text{1. 解析输入: } " + latex(expr))
        
        if isinstance(expr, Eq):
            # 如果是方程，则求解
            steps.append(r"\text{2. 识别为方程，进行求解}")
            
            # --- 尝试生成方程求解步骤 ---
            eq_steps = generate_equation_steps(expr)
            if eq_steps:
                steps.append(r"\text{--- 方程求解步骤 ---}")
                steps.extend(eq_steps)
                steps.append(r"\text{------------------}")
            # --------------------------

            # solve 返回一个列表
            solutions = solve(expr)
            # 将解集转换为 LaTeX
            result_latex = latex(solutions)
            steps.append(r"\text{3. 得到解集: } " + result_latex)
        else:
            # 3. 如果是表达式，执行核心运算
            steps.append(r"\text{2. 识别为表达式，执行运算}")
            
            # --- 尝试生成详细步骤 (针对积分) ---
            if isinstance(expr, Integral):
                integral_details = generate_integral_steps(expr)
                if integral_details:
                    steps.append(r"\text{--- 积分步骤详解 ---}")
                    steps.extend(integral_details)
                    steps.append(r"\text{------------------}")
            
            # --- 尝试生成详细步骤 (针对求导) ---
            elif isinstance(expr, Derivative):
                diff_details = generate_derivative_steps(expr)
                if diff_details:
                    steps.append(r"\text{--- 求导步骤 ---}")
                    steps.extend(diff_details)
                    steps.append(r"\text{------------------}")
            # --------------------------------
            
            # .doit() 会强制执行未计算的操作（如 Integral, Derivative, Limit）
            result = expr.doit()
            steps.append(r"\text{3. 运算结果: } " + latex(result))
            
            # 4. 可选：化简结果
            # simplify 可以让结果更简洁，例如 sin^2 + cos^2 -> 1
            final_result = simplify(result)
            if final_result != result:
                steps.append(r"\text{4. 化简结果: } " + latex(final_result))
            
            # 5. 将结果转换回 LaTeX
            result_latex = latex(final_result)
        
        print(f"Calculated Result: {result_latex}")
        
        return {"result": result_latex, "steps": steps}
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=f"Calculation error: {str(e)}")

if __name__ == "__main__":
    # 启动服务
    uvicorn.run(app, host="0.0.0.0", port=8000)
