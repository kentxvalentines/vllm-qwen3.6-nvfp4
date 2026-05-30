# Use the official vLLM OpenAI-compatible base image
FROM vllm/vllm-openai:latest

# Expose the API port
EXPOSE 8000

# Switch to root to install compiler dependencies for JIT kernel compilation
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ninja-build \
    cuda-toolkit \
    && rm -rf /var/lib/apt/lists/*

# Set CUDA environment variables so torch/ninja can locate nvcc
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# =========================================================================
# STRATEGY 1: LOCAL BUILD (Default)
# Copy the already-downloaded local model files and custom configuration files.
# =========================================================================
COPY . /model/

# =========================================================================
# STRATEGY 2: CLOUD BUILD (Commented Out)
# If building on GitHub Actions or a remote builder, comment out the COPY statements 
# above, uncomment the lines below, and provide your HF token if required.
# =========================================================================
# RUN pip install huggingface_hub
# RUN python3 -c "from huggingface_hub import snapshot_download; \
#     snapshot_download(repo_id='sakamakismile/Huihui-Qwen3.6-35B-A3B-Claude-4.7-Opus-abliterated-NVFP4', local_dir='/model')"

# Set environment variables for vLLM
ENV MODEL_PATH=/model
ENV PORT=8000
ENV MAX_MODEL_LEN=131072
ENV GPU_MEMORY_UTILIZATION=0.90
ENV SERVED_MODEL_NAME=qwen-3.6-35b-it-nvfp4
ENV KV_CACHE_DTYPE=fp8
ENV VLLM_ENABLE_CUDA_COMPATIBILITY=1

# Launch optimized vLLM engine for Qwen 3.6 NVFP4
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--model", "/model", \
     "--port", "8000", \
     "--served-model-name", "qwen-3.6-35b-it-nvfp4", \
     "--kv-cache-dtype", "fp8", \
     "--dtype", "bfloat16", \
     "--max-model-len", "131072", \
     "--gpu-memory-utilization", "0.90", \
     "--enable-auto-tool-choice"]
