#! /usr/bin/env python3
import subprocess
import sys

def create_shared_object(num_functions_range: range, filename: str) -> None:
    """Create a shared object file with a given number of functions."""
    functions = [
        f"void function_{i}() {{ printf(\"Function {i} called\\n\"); }}\n"
        for i in num_functions_range
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

def create_executable_file(shared_object_names: list[str], num_functions: int, filename: str) -> None:
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

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <num_functions> <num_shared_objects>")
        sys.exit(1)

    num_functions = int(sys.argv[1])
    num_shared_objects = int(sys.argv[2])
    filename = f"{num_functions}_functions_{num_shared_objects}_shared_objects"

    print(f"Generating {num_shared_objects} shared object with {num_functions} each and executable")
    total_functions = num_functions * num_shared_objects
    print(f"Total functions: {total_functions}")
    
    for i in range(num_shared_objects):
        create_shared_object(range(i * num_functions, (i + 1) * num_functions), f"{filename}_{i}")
    shared_objects = [f"{filename}_{i}.so" for i in range(num_shared_objects)]
    create_executable_file(shared_objects, total_functions, "benchmark")