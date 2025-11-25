
try:
    import sympy.integrals.manualintegrate as manualintegrate
    print("Available attributes in sympy.integrals.manualintegrate:")
    for attr in dir(manualintegrate):
        if "Rule" in attr:
            print(attr)
except ImportError as e:
    print(f"Error importing manualintegrate: {e}")
