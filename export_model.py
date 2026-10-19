#!/usr/bin/env python3
# Copyright 2026 Arm Limited and/or its affiliates.
# SPDX-License-Identifier: Apache-2.0
"""Export model/model.py to a TinyCNN .pte for the native Zephyr application."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def run_in_venv() -> None:
    """Use the model-export environment created by setup_venv.py."""
    venv = HERE / ".venv"
    if Path(sys.prefix).resolve() == venv.resolve():
        return
    python = venv / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    if not python.is_file():
        sys.exit("Create .venv first: setup_venv.bat (Windows) or ./setup_venv.sh")
    sys.exit(subprocess.run([str(python), __file__, *sys.argv[1:]]).returncode)


def export_model(spec, params: dict) -> bytes:
    """Quantize model/model.py, delegate it to the Ethos-U and return the .pte."""
    import torch
    from executorch.backends.arm.ethosu import EthosUPartitioner
    from executorch.backends.arm.quantizer import EthosUQuantizer, get_symmetric_quantization_config
    from executorch.exir import EdgeCompileConfig, ExecutorchBackendConfig, to_edge_transform_and_lower
    from torchao.quantization.pt2e.quantize_pt2e import convert_pt2e, prepare_pt2e

    sys.path.insert(0, str(HERE / "model"))
    from model import get_calibration_inputs, get_model

    model = get_model(**{k: v for k, v in params.items() if k == "input_shape"})
    samples = get_calibration_inputs(**params)
    example = (samples[0],)
    graph = torch.export.export(model, example).module()

    # Quantize the whole graph so the partitioner can move every node into the
    # Ethos-U delegate; only a float<->int8 boundary stays on the CPU.
    quantizer = EthosUQuantizer(spec)
    quantizer.set_global(get_symmetric_quantization_config(is_per_channel=True))
    prepared = prepare_pt2e(graph, quantizer)
    with torch.no_grad():
        for sample in samples:
            prepared(sample)  # calibrate
    quantized = convert_pt2e(prepared)

    edge = to_edge_transform_and_lower(
        torch.export.export(quantized, example),
        partitioner=[EthosUPartitioner(spec)],
        compile_config=EdgeCompileConfig(_check_ir_validity=False),
    )
    program = edge.to_executorch(ExecutorchBackendConfig(extract_delegate_segments=False))
    return bytes(program.buffer)



def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=HERE / "ai_layer/model.pte")
    args = parser.parse_args()
    run_in_venv()

    from executorch.backends.arm.ethosu import EthosUCompileSpec

    spec = EthosUCompileSpec(
        target="ethos-u85-256",
        system_config="Ethos_U85_SYS_DRAM_Mid",
        memory_mode="Shared_Sram",
    )
    pte = export_model(spec, {"input_shape": (1, 16, 16, 3), "calibration_samples": 2})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(pte)
    print(f"Exported {len(pte)} bytes to {args.output}")


if __name__ == "__main__":
    main()
