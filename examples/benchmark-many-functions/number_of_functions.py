#! /usr/bin/env python3
import os
import subprocess
import sys

def create_shared_object(num_functions: int, filename: str) -> None:
    """Create a shared object file with a given number of functions."""
    functions = [
        f"void function_{i}() {{ printf(\"Function {i} called\\n\"); }}\n"
        for i in range(num_functions)
    ]
    functions_str = "".join(functions)
    source_code = f"""
    #include <stdio.h>
    {functions_str}
    """
    source_file_name = f"{filename}.c"
    with open(source_file_name, "w") as source_file:
        source_file.write(source_code)
        source_file.flush()

        shared_object_name = f"{filename}.so"
        subprocess.run(["gcc", "-shared", "-fPIC", "-o", shared_object_name, source_file_name])

def create_executable_file(shared_object_name: str, num_functions: int, filename: str) -> None:
    """Create an executable that uses symbols from a shared object."""
    extern_function_definitions = [
        f"extern int function_{i}();\n" for i in range(num_functions)
    ]
    function_calls = [
        f"function_{i}();\n" for i in range(num_functions)
    ]
    main_content = "".join(function_calls)
    content = f"""
    #include <stdio.h>
    {"".join(extern_function_definitions)}
    int main() {{
    {main_content}
    return 0;
    }}
    """
    main_file_name = f"{filename}.c"
    with open(main_file_name, "w") as main_file:
        main_file.write(content)
        main_file.flush()

        executable_name = filename
        subprocess.run(["gcc", "-o", executable_name, main_file_name, shared_object_name])

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <num_functions>")
        sys.exit(1)

    num_functions = int(sys.argv[1])
    filename = f"{num_functions}_functions"

    print(f"Generating shared object and executable for {num_functions} functions")
    create_shared_object(num_functions, filename)
    create_executable_file(f"{filename}.so", num_functions, filename)
    print(f"Generated files: {filename}.c, {filename}.so, {filename}")