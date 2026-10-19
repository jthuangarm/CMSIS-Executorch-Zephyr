# CMSIS-Executorch-Zephyr

Extends ExecuTorch's [hello-executorch](https://github.com/pytorch/executorch/tree/v1.5.1/zephyr/samples/hello-executorch) with TinyCNN and Keil Studio integration. Uses the existing Zephyr v4.4.2 / ExecuTorch v1.5.1 environment.

## Build and run

1. Export TinyCNN to `ai_layer/model.pte`:

   ```bat
   .venv\Scripts\python.exe export_model.py
   ```

2. Open `cmsis-executorch.csolution.yml` in Keil Studio and select **SSE-320-U85 / Debug**.
3. Select **Build**, then **Load & Run**. Check for `Model executed successfully.` and ten output values. FVP exits at `--simlimit 60`.

The solution builds `zephyr_native_app` through west. Its `ET_PTE_FILE_PATH` already points to the exported model; update it only when changing the model location.

## Required changes from upstream

In `zephyr_native_app/CMakeLists.txt`:

- Find the installed `flatc.exe` to avoid the Windows Ninja byproduct mismatch.
- Add `add_dependencies(executorch_core zephyr_generated_headers)` so generated Zephyr headers exist before compilation.
- Exclude unused `flatcc_ep` / `flatccrt` targets on Windows to avoid building them with the embedded compiler.
- Register TinyCNN's selected quantize/dequantize operators through `tinycnn_quantized_ops_lib`.

In `boards/mps4_corstone320_fvp.conf`, disable UART and enable semihosting to avoid the observed GPIO/pinctrl startup fault:

```conf
CONFIG_SERIAL=n
CONFIG_SEMIHOST=y
CONFIG_SEMIHOST_CONSOLE=y
```

The FVP configuration enables semihosting and sets 256 NPU MACs to match the exported model.
