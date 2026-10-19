# CMSIS ExecuTorch on Zephyr

- Run TinyCNN on the Corstone-320 FVP with Zephyr's native ExecuTorch module.
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

- The native application embeds `ai_layer/model.pte`.
- Skip `cbuild zephyr --module cmsis_ai ...`; runtime libraries now come from Zephyr's ExecuTorch module.

## 2. Build and test

1. Open `cmsis-executorch.csolution.yml` in Keil Studio.
2. Select **SSE-320-U85 / Debug**, then **Build**.
3. Select **Load & Run**.
4. Check for `Model executed successfully.`, ten output values, and `SUCCESS: Program complete, exiting.`

## 3. Native ExecuTorch integration changes

- **[cmsis-executorch.csolution.yml](cmsis-executorch.csolution.yml)**
  - Set the west app to `zephyr_native_app`, board `mps4/corstone320/fvp`.
  - Pass `ET_PTE_FILE_PATH: ../../../../ai_layer/model.pte` to select the model.
- **[CMakeLists.txt](zephyr_native_app/CMakeLists.txt)**
  - Base the app on upstream `hello-executorch`; register TinyCNN's quantize/dequantize operators.
  - Fix build ordering with `add_dependencies(executorch_core zephyr_generated_headers)`.
  - Windows workarounds: use installed `flatc.exe` and exclude unused `flatcc_ep` / `flatccrt` targets.
  - The `flatc` filename mismatch is not expected on Linux; Linux is untested.
- **[prj.conf](zephyr_native_app/prj.conf)**
  - Increase method and temporary allocator pools to 64 KiB each for this model; tune for other models.
- **[mps4_corstone320_fvp.conf](zephyr_native_app/boards/mps4_corstone320_fvp.conf)**
  - Select the Ethos-U85 256-MAC driver configuration.
  - Use semihosting with serial disabled to avoid the observed FVP UART startup fault.
- **[fvp_config.txt](board/Corstone-320/fvp_config.txt)**
  - Match the model's 256 MACs and enable semihosting output.
