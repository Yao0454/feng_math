
content = r'''import sys
import typing

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
from sympy import latex, simplify, Eq, solve, Integral, Derivative
from sympy.integrals.manualintegrate import (
    integral_steps, 
    PartsRule, 
    URule, 
    PowerRule, 
    AddRule, 
    ConstantRule, 
    TrigRule,
    ReciprocalRule,
    ConstantTimesRule
)
import uvicorn

app = FastAPI()

class MathRequest(BaseModel):
    latex: str

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
                res.append(indent + r"\text{应用分部积分法: } \int u dv = uv - \int v du")
                res.append(indent + r"\quad u = " + latex(r.u) + r", \quad dv = " + latex(r.dv))
                res.append(indent + r"\quad du = " + latex(r.du) + r", \quad v = " + latex(r.v))
                res.append(indent + r"\quad \Rightarrow " + latex(r.u * r.v) + r" - \int " + latex(r.v * r.du))
                if r.second_step:
                    res.extend(parse_rule(r.second_step, depth + 1))
            
            elif isinstance(r, URule):
                res.append(indent + r"\text{应用换元法: } u = " + latex(r.u_func))
                # res.append(indent + r"\quad du = " + latex(r.constant * r.u_var) + r" dx") # 近似表达
                if r.substep:
                    res.extend(parse_rule(r.substep, depth + 1))
            
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
        expr = latex2sympy(fixed_latex)
        
        # 2. 判断是否为方程 (Equality)
        steps = []
        steps.append(r"\text{1. 解析输入: } " + latex(expr))
        
        if isinstance(expr, Eq):
            # 如果是方程，则求解
            steps.append(r"\text{2. 识别为方程，进行求解}")
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
        raise HTTPException(status_code=400, detail=f"Calculation error: {str(e)}")

if __name__ == "__main__":
    # 启动服务
    uvicorn.run(app, host="0.0.0.0", port=8000)
'''

with open('backend/main.py', 'w') as f:
    f.write(content)
