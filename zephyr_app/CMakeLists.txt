cmake_minimum_required(VERSION 3.20.0)

list(APPEND ZEPHYR_EXTRA_MODULES
    "${CMAKE_CURRENT_LIST_DIR}/../cmsis_ai"
)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(tinycnn_zephyr LANGUAGES C CXX)

zephyr_include_directories(
    "${CMAKE_CURRENT_LIST_DIR}/../ai_layer"
    "${ZEPHYR_HAL_ETHOS_U_MODULE_DIR}/include"
)

target_sources(app PRIVATE
    ../board/Corstone-320/main.c
    ../src/app_main.cpp
    ../src/arm_embedded_module.cpp
    ../ai_layer/model_pte.c
)

target_compile_definitions(app PRIVATE
    APP_METHOD_POOL_SIZE=65536
    APP_TEMP_POOL_SIZE=65536
)
