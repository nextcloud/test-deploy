"""Modified basic example for testing problems with deployment"""

from contextlib import asynccontextmanager

import httpx
import torch
from fastapi import BackgroundTasks, FastAPI, responses
from nc_py_api import NextcloudApp
from nc_py_api.ex_app import (
    AppAPIAuthMiddleware,
    get_computation_device,
    run_app,
    set_handlers,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    set_handlers(app, enabled_handler, default_heartbeat=False, default_init=False)
    yield


APP = FastAPI(lifespan=lifespan)
APP.add_middleware(AppAPIAuthMiddleware)


@APP.get("/heartbeat")
async def heartbeat_callback():
    print("Heartbeat was called")
    return responses.JSONResponse(content={"status": "ok"})


def report_init_status() -> None:
    nc = NextcloudApp()
    nextcloud_url = nc.app_cfg.endpoint
    print(f"Try default url to report the init status: {nextcloud_url}", flush=True)
    try:
        nc.set_init_status(100)
        print("Connect to Nextcloud was successful", flush=True)
        return
    except Exception as e:
        print(e, flush=True)
    print(flush=True)
    print("ERROR occurred! Can't report the ExApp status to the Nextcloud instance.", flush=True)
    if nextcloud_url.startswith("https://"):
        nextcloud_url = nextcloud_url.replace("https:", "http:")
        print(f"Try send request using HTTP instead of HTTPS: {nextcloud_url}", flush=True)
        try:
            r = httpx.get(
                nextcloud_url.rstrip("/") + "/ocs/v1.php/cloud/capabilities",
                headers={
                    "OCS-APIRequest": "true",
                    "User-Agent": f"ExApp/{nc.app_cfg.app_name}/{nc.app_cfg.app_version} (httpx/{httpx.__version__})",
                }
            )
            if httpx.codes.is_error(r.status_code):
                print("Unsuccessful. Can not determine correct URL of the Nextcloud instance.", flush=True)
            else:
                print(
                    "[IMPORTANT] Success. Maybe HTTP should be used? Check your infrastructure configuration.",
                    flush=True,
                )
        except Exception:  # noqa
            print("Unsuccessful. Can not determine correct URL of the Nextcloud instance.", flush=True)


@APP.post("/init")
async def init_callback(b_tasks: BackgroundTasks):
    print("Init was called", flush=True)
    b_tasks.add_task(report_init_status)
    return responses.JSONResponse(content={})


def enabled_handler(enabled: bool, _nc: NextcloudApp) -> str:
    print(f"enabled_handler: enabled={bool(enabled)}", flush=True)
    r = ""
    if get_computation_device() == "CUDA":
        print("Get CUDA information", flush=True)
        print("is available:", torch.cuda.is_available(), flush=True)
        if torch.cuda.is_available():
            print("torch version:", torch.version.cuda, flush=True)
            if torch.version.cuda:
                print("device count:", torch.cuda.device_count(), flush=True)
                if torch.cuda.device_count():
                    print("current device index:", torch.cuda.current_device(), flush=True)
                    print("device name:", torch.cuda.get_device_name(torch.cuda.current_device()), flush=True)
                else:
                    r = "Error: Device count is zero"
            else:
                r = "Error: torch is not build with CUDA support"
        else:
            r = "Error: CUDA is not available"
    elif get_computation_device() == "ROCM":
        print("Get ROCM information", flush=True)
        print("is available:", torch.cuda.is_available(), flush=True)
        if torch.cuda.is_available():
            print("torch version:", torch.version.hip, flush=True)
            if torch.version.hip:
                print("device count:", torch.cuda.device_count(), flush=True)
                if torch.cuda.device_count():
                    print("current device index:", torch.cuda.current_device(), flush=True)
                    print("device name:", torch.cuda.get_device_name(torch.cuda.current_device()), flush=True)
                else:
                    r = "Error: Device count is zero"
            else:
                r = "Error: torch is not build with HIP support"
        else:
            r = "Error: ROCM is not available"
    else:
        print("Running on CPU", flush=True)
    print(r)
    return r


if __name__ == "__main__":
    print("Started", flush=True)
    run_app("main:APP", log_level="trace")
