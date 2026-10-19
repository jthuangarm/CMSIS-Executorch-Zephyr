# CMSIS-Executorch-Zephyr

Run TinyCNN on Zephyr with the native ExecuTorch module and an Ethos-U85-256 on the Corstone-320 FVP. Keil Studio uses the solution's `west` project to build `zephyr_native_app` and its Arm-FVP target to run the ELF.

The application starts from ExecuTorch v1.5.1's [`hello-executorch`](https://github.com/pytorch/executorch/tree/v1.5.1/zephyr/samples/hello-executorch) sample. The runtime, kernels and Ethos-U driver come from the Zephyr workspace.

## Setup

Use Zephyr v4.4.2 with ExecuTorch v1.5.1, Keil Studio, and the tools selected in `vcpkg-configuration.json`.

With the Zephyr workspace's Python environment active, run from this repository:

```bat
setup_venv.bat
python -m pip install -r requirements.txt
python -m pip install --no-deps -r requirements-arm-tosa.txt
```

## Prepare the model

Export the supplied untrained TinyCNN using the project's environment:

```bat
.venv\Scripts\python.exe export_model.py
```

This quantizes `model/model.py`, delegates it to `ethos-u85-256`, and writes `ai_layer/model.pte`. No CMSIS AI layer, C array, or exported runtime module is generated. The Python exporter and west module must both use ExecuTorch v1.5.1. Export again after changing the model; the `.pte` is generated and is not committed.

## Build and run

Open `cmsis-executorch.csolution.yml` in Keil Studio, select **SSE-320-U85 / Debug**, then use **Build** and **Load & Run**.

The solution points to the model through:

```yaml
west-defs:
  - ET_PTE_FILE_PATH: ../../../../ai_layer/model.pte
```

CMSIS-Toolbox invokes CMake from `tmp/SSE-320-U85/default/1`, so four `..` segments return to the solution directory. The application CMake resolves and checks the model path before embedding it. Keep this relative path when moving the whole repository.

Successful output includes `Model executed successfully.`, the ten TinyCNN output values, and `SUCCESS: Program complete, exiting.` The weights are untrained; this checks inference and integration, not classification accuracy. FVP uses `--simlimit 60` to end the CMSIS Run task after 60 seconds of simulated time; returning from the Zephyr application's `main` does not shut down the simulator.

## Changes from the upstream sample

### CMakeLists.txt

The native application keeps upstream module discovery and selected operator generation. The following changes were needed in the tested Windows/Ninja environment:

| Problem | Change in `zephyr_native_app/CMakeLists.txt` |
| --- | --- |
| Ninja expects `flatc.exe`, but the source-built host-tool rule declares a different byproduct. | Find the installed `flatc.exe` before `find_package(Zephyr ...)`, using the active Python environment's `executorch/data/bin`. |
| ExecuTorch's Zephyr platform source can compile before `zephyr/heap_constants.h` exists. | Add `add_dependencies(executorch_core zephyr_generated_headers)`. |
| The unused `flatcc` host build picks the embedded compiler and fails to link Windows system libraries. | Exclude `flatcc_ep` and `flatccrt` from the default Windows build when devtools, pybind and Cadence are disabled. Enabling those features needs a working host-tool build. |
| TinyCNN retains quantize/dequantize operators around the NPU delegate. | Generate `tinycnn_quantized_ops_lib` from `kernels/quantized/quantized.yaml`, select operators from the `.pte`, and link the registrations with `quantized_kernels`. |

These fixes are local to this application; the west-managed ExecuTorch source stays unchanged. The upstream sample's existing install-rule setting and model-header generation are retained.

### Zephyr and FVP configuration

`prj.conf` enables ExecuTorch, C++17 and float output, and gives TinyCNN 64 KiB each for its method and temporary allocators. Portable operator registration stays disabled globally; CMake registers the model's selected operators.

The tested original UART configuration faulted during GPIO/pinctrl initialization before entering the model runner. `boards/mps4_corstone320_fvp.conf` uses the same console workaround as our successful run:

```conf
CONFIG_ETHOS_U=y
CONFIG_ETHOS_U85_256=y
CONFIG_SERIAL=n
CONFIG_SEMIHOST=y
CONFIG_SEMIHOST_CONSOLE=y
```

The FVP config enables semihosting and sets 256 NPU MACs to match the exported model. The UART startup fault was observed on this FVP setup; its underlying cause was not established as Windows-specific.
