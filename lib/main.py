"""Modified basic example for testing problems with deployment"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, responses, BackgroundTasks
from nc_py_api import NextcloudApp
from nc_py_api.ex_app import AppAPIAuthMiddleware, run_app, set_handlers, get_computation_device
import torch


@asynccontextmanager
async def lifespan(app: FastAPI):
    set_handlers(app, enabled_handler, default_heartbeat=False, default_init=False)
    yield


APP = FastAPI(lifespan=lifespan)
APP.add_middleware(AppAPIAuthMiddleware)


@APP.get("/heartbeat")
async def heartbeat_callback():
    print(f"Heartbeat was called")
    return responses.JSONResponse(content={"status": "ok"})


def report_init_status() -> None:
    nc = NextcloudApp()
    print(f"Try default url to report the init status: {nc.app_cfg.endpoint}")
    try:
        nc.set_init_status(100)
        print("Connect to Nextcloud was successful")
        return
    except Exception as e:
        print(e)
    print()
    print("ERROR occurred! Can't report the ExApp status to the Nextcloud instance.")


@APP.post("/init")
async def init_callback(b_tasks: BackgroundTasks):
    print("Init was called")
    b_tasks.add_task(report_init_status)
    return responses.JSONResponse(content={})


def enabled_handler(enabled: bool, _nc: NextcloudApp) -> str:
    print(f"enabled_handler: enabled={str(bool(enabled))}")
    r = ""
    if get_computation_device() == "CUDA":
        print("Get CUDA information")
        print("is available:", torch.cuda.is_available())
        if torch.cuda.is_available():
            print("device count:", torch.cuda.device_count())
            if torch.cuda.device_count():
                print("current device index:", torch.cuda.current_device())
                print("device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
            else:
                r = "Error: Device count is zero"
        else:
            r = "Error: CUDA is not available"
    elif get_computation_device() == "ROCM":
        print("Get ROCM information")
        print("is available:", torch.cuda.is_available())
        if torch.cuda.is_available():
            print("device count:", torch.cuda.device_count())
            if torch.cuda.device_count():
                print("current device index:", torch.cuda.current_device())
                print("device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
            else:
                r = "Error: Device count is zero"
        else:
            print("TO-DO")
            r = ""
    else:
        print("Running on CPU")
    print(r)
    return r


if __name__ == "__main__":
    run_app("main:APP", log_level="trace")
