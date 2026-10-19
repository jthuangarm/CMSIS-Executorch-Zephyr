# CMSIS ExecuTorch on Zephyr

- Run TinyCNN on the Corstone-320 FVP with Zephyr's native ExecuTorch module.
- Keep main's `create_ai_layer.py` and `ai_layer/ai_layer.clayer.yml` workflow.
- Use the existing Zephyr v4.4.2 / ExecuTorch v1.5.1 environment.

## 1. Export the AI layer

- Generate the AI layer and model using the original flow.

**Windows:**

```powershell
.\setup_venv.bat
cbuild setup cmsis-executorch.csolution.yml --active SSE-320-U85 --packs
python create_ai_layer.py cmsis-executorch.cbuild-mlops.yml
```

**Linux / macOS:**

```bash
bash setup_venv.sh
cbuild setup cmsis-executorch.csolution.yml --active SSE-320-U85 --packs
python3 create_ai_layer.py cmsis-executorch.cbuild-mlops.yml
```

- Keep the generated AI clayer and model files.
- The native application embeds `ai_layer/model.pte`.
- Skip `cbuild zephyr --module cmsis_ai ...`; runtime libraries now come from Zephyr's ExecuTorch module.

## 2. Build and test

1. Open `cmsis-executorch.csolution.yml` in Keil Studio.
2. Select **SSE-320-U85 / Debug**, then **Build**.
3. Select **Load & Run**.
4. Check for `Model executed successfully.`, ten output values, and `SUCCESS: Program complete, exiting.`

## 3. Native ExecuTorch integration changes

- **[cmsis-executorch.csolution.yml](cmsis-executorch.csolution.yml)**
  - Keep the AI-Layer variable, `mlops:` settings and pack reference used by `create_ai_layer.py`.
  - Point the west project to `zephyr_native_app`, using board `mps4/corstone320/fvp`.
  - Pass `ET_PTE_FILE_PATH: ../../../../ai_layer/model.pte` to embed the generated model.
  - Keep `--simlimit 60` in the solution so CMSIS Run ends after the program completes.
- **[CMakeLists.txt](zephyr_native_app/CMakeLists.txt)**
  - Use native ExecuTorch module discovery and model-header generation from the upstream `hello-executorch` sample.
  - Find the installed `flatc.exe` to avoid the Windows Ninja byproduct mismatch.
  - Add `add_dependencies(executorch_core zephyr_generated_headers)` to wait for generated Zephyr headers.
  - Exclude unused `flatcc_ep` / `flatccrt` targets on Windows; their host build otherwise picks the embedded compiler.
  - Generate `tinycnn_quantized_ops_lib` for the model's quantize/dequantize operators.
- **[prj.conf](zephyr_native_app/prj.conf)**
  - Enable ExecuTorch, C++17 and floating-point output.
  - Set the method and temporary allocator pools to 64 KiB each for TinyCNN.
- **[mps4_corstone320_fvp.conf](zephyr_native_app/boards/mps4_corstone320_fvp.conf)**
  - Enable `CONFIG_ETHOS_U=y` and `CONFIG_ETHOS_U85_256=y`.
  - Set `CONFIG_SERIAL=n`, `CONFIG_SEMIHOST=y` and `CONFIG_SEMIHOST_CONSOLE=y` for FVP output.
  - This avoids the observed UART GPIO/pinctrl startup fault before the model runner.
- **[fvp_config.txt](board/Corstone-320/fvp_config.txt)**
  - Enable semihosting and set 256 NPU MACs to match the exported model.
