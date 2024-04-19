#! /usr/bin/env python3
import pprint
import sqlite3
import subprocess
import tempfile
import timeit

def create_shared_object(num_functions: int) -> str:
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
    with tempfile.NamedTemporaryFile("w", delete=False, suffix=".c") as source_file:
        source_file.write(source_code)
        source_file.flush()

        shared_object_name = tempfile.NamedTemporaryFile(delete=False, suffix=".so").name
        subprocess.run(["./build/bin/musl-gcc", "-shared", "-fPIC", "-o", shared_object_name, source_file.name])
        return shared_object_name

def create_executable_file(shared_object_name: str, num_functions: int) -> str:
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
    with tempfile.NamedTemporaryFile("w", delete=False, suffix=".c") as main_file:
        main_file.write(content)
        main_file.flush()

        executable_name = tempfile.NamedTemporaryFile(delete=False, suffix="").name
        subprocess.run(["./build/bin/musl-gcc", "-o", executable_name, main_file.name, shared_object_name])
        return executable_name

def benchmark_loading(binary_name: str) -> float:
    """Benchmark the time taken to start the binary and return immediately."""
    command = f"{binary_name}"
    timer = timeit.Timer(lambda: subprocess.run(command, capture_output=True))
    return min(timer.repeat(3, 1))

data = {"Number of Functions": [], "Load Time": []}

for exponent in range(1, 6):
    num_functions = 10 ** exponent
    data["Number of Functions"].append(num_functions)

    print(f"Generating shared object and executable for {num_functions} functions")
    shared_object = create_shared_object(num_functions)
    binary_file = create_executable_file(shared_object, num_functions)

    print(f"Running the benchmark on executable {binary_file} and shared object {shared_object}")
    load_time = benchmark_loading(binary_file)
    data["Load Time"].append(load_time)

pprint.pprint(data)
