set(CMSIS_PACK_ROOT $ENV{CMSIS_PACK_ROOT})
cmake_path(SET PYTORCH_EXECUTORCH NORMALIZE "${CMSIS_PACK_ROOT}/PyTorch/ExecuTorch/1.5.1")

if(NOT EXISTS "${PYTORCH_EXECUTORCH}/PyTorch.ExecuTorch.pdsc")
  message(FATAL_ERROR "Pack(s) not found. Set pack path or CMSIS_PACK_ROOT.")
endif()

zephyr_compile_definitions(
  ET_LOG_ENABLED=0
  ARMCM85
  _RTE_
)

# RTE_Components.h (CMSIS-Pack component selection header)
zephyr_include_directories(
  "${CMAKE_CURRENT_LIST_DIR}"
)

# Pre_Include_Global.h (CMSIS-Pack global pre-include header)
zephyr_compile_options(
  "SHELL:-include \"${CMAKE_CURRENT_LIST_DIR}/Pre_Include_Global.h\""
)

# ── PyTorch::Machine Learning:ExecuTorch:Runtime ──────────────────────────
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_RUNTIME)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_runtime)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/kernels/quantized/cpu/embeddingxb.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/backend/interface.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/device_allocator.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/device_memory_buffer.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/evalue.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/exec_aten/util/tensor_shape_to_c_string.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/exec_aten/util/tensor_util_portable.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/portable_type/tensor_impl.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/tag.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/core/tensor_layout.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/method.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/method_meta.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/program.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/program_validation.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/pte_data_map.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/tensor_parser_exec_aten.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/executor/tensor_parser_portable.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/kernel/operator_registry.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/abort.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/default/minimal.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/log.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/platform.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/profiler.cpp"
    "${PYTORCH_EXECUTORCH}/src/runtime/platform/runtime.cpp"
    "${PYTORCH_EXECUTORCH}/src/schema/extended_header.cpp"
  )

  zephyr_include_directories(
    "${PYTORCH_EXECUTORCH}/include"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()

# ── PyTorch::Machine Learning:ExecuTorch:Kernel Utils ─────────────────────
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_KERNEL_UTILS)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_kernel_utils)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/pattern/unary_ufunc_realhbbf16_to_bool.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/pattern/unary_ufunc_realhbbf16_to_floathbf16.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/pattern/unary_ufunc_realhbf16.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/activation_ops_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/advanced_index_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/arange_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/broadcast_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/copy_ops_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/delinearize_index.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/distance_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/dtype_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/grid_sampler_2d_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/index_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/kernel_ops_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/matmul_ops_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/normalization_ops_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/padding_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/reduce_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/repeat_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/select_copy_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/slice_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/stack_util.cpp"
    "${PYTORCH_EXECUTORCH}/src/kernels/portable/cpu/util/upsample_util.cpp"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()

# ── PyTorch::Machine Learning:ExecuTorch:Kernel Registration ──────────────
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_KERNEL_REGISTRATION)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_kernel_registration)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/registration/RegisterAllKernels.cpp"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()

# ── PyTorch::Machine Learning:ExecuTorch:Backend EthosU ───────────────────
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_BACKEND_ETHOSU)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_backend_ethosu)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/backends/arm/runtime/EthosUBackend.cpp"
    "${PYTORCH_EXECUTORCH}/src/backends/arm/runtime/EthosUBackend_Cortex_M.cpp"
    "${PYTORCH_EXECUTORCH}/src/backends/arm/runtime/EthosUBackend_IoMemcpy.cpp"
    "${PYTORCH_EXECUTORCH}/src/backends/arm/runtime/VelaBinStream.cpp"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()

# ── PyTorch::Machine Learning:ExecuTorch Operators:Quantized dequantize ───
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_OPERATORS_QUANTIZED_DEQUANTIZE)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_operators_quantized_dequantize)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/kernels/quantized/cpu/op_dequantize.cpp"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()

# ── PyTorch::Machine Learning:ExecuTorch Operators:Quantized quantize ─────
if(CONFIG_CMSIS_AI_LAYER_PYTORCH_MACHINE_LEARNING_EXECUTORCH_OPERATORS_QUANTIZED_QUANTIZE)

  zephyr_library_named(ai_layer_pytorch_machine_learning_executorch_operators_quantized_quantize)

  zephyr_library_sources(
    "${PYTORCH_EXECUTORCH}/src/kernels/quantized/cpu/op_quantize.cpp"
  )

  zephyr_library_compile_options(-std=c++17 -fno-rtti -fno-exceptions)

endif()
