# This file is licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Helper macros to configure triton overlay project."""

# This is adapted from llvm-project's utils/bazel/configure.bzl

DEFAULT_OVERLAY_PATH = "triton-overlay"

def _overlay_directories(repository_ctx):
    src_path = repository_ctx.path(Label("//:WORKSPACE")).dirname
    bazel_path = src_path.get_child("bazel")
    overlay_path = bazel_path.get_child("triton-overlay")
    script_path = bazel_path.get_child("overlay_directories.py")

    python_bin = repository_ctx.which("python3")
    if not python_bin:
        # Windows typically just defines "python" as python3. The script itself
        # contains a check to ensure python3.
        python_bin = repository_ctx.which("python")

    if not python_bin:
        fail("Failed to find python3 binary")

    cmd = [
        python_bin,
        script_path,
        "--src",
        src_path,
        "--overlay",
        overlay_path,
        "--target",
        ".",
    ]
    exec_result = repository_ctx.execute(cmd, timeout = 20)

    if exec_result.return_code != 0:
        fail(("Failed to execute overlay script: '{cmd}'\n" +
              "Exited with code {return_code}\n" +
              "stdout:\n{stdout}\n" +
              "stderr:\n{stderr}\n").format(
            cmd = " ".join([str(arg) for arg in cmd]),
            return_code = exec_result.return_code,
            stdout = exec_result.stdout,
            stderr = exec_result.stderr,
        ))
    patch_file = str(repository_ctx.path(repository_ctx.attr.patch).realpath)
    print(patch_file)
    if patch_file:
        cmd = ["bash", "-c", "patch -p0 < " + patch_file]
        exec_result = repository_ctx.execute(cmd, timeout = 20)
        if exec_result.return_code != 0:
            fail(("Failed to execute patch script: '{cmd}'\n" +
                  "Exited with code {return_code}\n" +
                  "stdout:\n{stdout}\n" +
                  "stderr:\n{stderr}\n").format(
                cmd = " ".join([str(arg) for arg in cmd]),
                return_code = exec_result.return_code,
                stdout = exec_result.stdout,
                stderr = exec_result.stderr,
            ))

def _triton_configure_impl(repository_ctx):
    _overlay_directories(repository_ctx)

triton_configure = repository_rule(
    implementation = _triton_configure_impl,
    local = True,
    configure = True,
    attrs={
        "patch" : attr.label(mandatory=True)
    },
)
