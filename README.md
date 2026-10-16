# CMSIS ExecuTorch on Zephyr

Run [CMSIS-Executorch](https://github.com/Arm-Examples/CMSIS-Executorch)'s TinyCNN on the Corstone-320 FVP (Cortex-M85, Ethos-U85-256) with Zephyr.

## 1. Export the AI layer

Generate the AI layer and embedded model first. Skip this step if using the AI layer and model files already provided in this repository:

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

Export `ai_layer/` as a Zephyr module. See [CMSIS-Toolbox documentation - Zephyr Module Export](https://open-cmsis-pack.github.io/cmsis-toolbox/Experimental-Features/#zephyr-module-export).

```sh
cbuild zephyr --module cmsis_ai --clayer ai_layer/ai_layer.clayer.yml --device ARMCM85 --toolchain GCC
```

## 2. Build and test

1. Open `cmsis-executorch.csolution.yml` in Keil Studio for VS Code.
2. In **Manage Solution**, confirm the debugger is `Arm-FVP` and the configuration file is `board/Corstone-320/fvp_config.txt`, then click **Build** in the CMSIS view.
3. Click **Load & Run** to run FVP. Check the terminal for `Output: 10 element(s): ...` and `Test_result: PASS`.

## 3. Zephyr integration changes from CMSIS-Executorch

- **[CMakeLists.txt](zephyr_app/CMakeLists.txt)**
  - Register `cmsis_ai`, which supplies the exported Pack components' sources and headers.
  - Manually add all remaining application sources and header search paths.
  - **The model files listed in the AI layer are expected to be included in the export, but currently need manual integration: add `ai_layer/model_pte.c` to the application sources and `ai_layer/` to the header search paths in CMakeLists.txt.**
  - Adjust the inference memory pools to fit this target.
- **[prj.conf](zephyr_app/prj.conf)**
  - Enable C++ support and floating-point output; configure stack and heap sizes.
  - Enable the U85-256 NPU driver.
  - **For this FVP example**, use semihosting for terminal output: disable Serial/UART with `CONFIG_SERIAL=n`, and enable `CONFIG_SEMIHOST=y` and `CONFIG_SEMIHOST_CONSOLE=y`.
- **[cmsis-executorch.csolution.yml](cmsis-executorch.csolution.yml)**
  - Switch from `cproject` to `west`, using `zephyr_app` and board `mps4/corstone320/fvp`.
- **Board layer and main**
  - Remove the Board layer; Zephyr handles startup, memory layout and driver initialization.
  - Simplify `main.c` to call `app_main()` and remove unused declarations from `main.h`.
- **[fvp_config.txt](board/Corstone-320/fvp_config.txt)**
  - Reset vector: replace the old bare-metal `0x12000000` / `regions_SSE-320.h` explanation with a note to match the Zephyr image's vector table.
  - Semihosting: replace the `retarget_stdio.c` explanation with Zephyr's `CONFIG_SEMIHOST_CONSOLE` output path.
  - Only comments changed; all FVP parameter values remain unchanged.

Reuse the existing inference code, model and FVP settings.
