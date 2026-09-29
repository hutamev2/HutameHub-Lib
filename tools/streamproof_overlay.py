"""Local Drawing bridge. Windows 10 2004+; Python standard library only.

The overlay owns its HWND and excludes that window with WDA_EXCLUDEFROMCAPTURE.
It does not change Roblox's display affinity or capture any screen pixels.
"""
import argparse
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import secrets
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import tkinter as tk

parser = argparse.ArgumentParser()
parser.add_argument("--pid", type=int, required=True)
parser.add_argument("--port", type=int, default=18764)
parser.add_argument("--config", type=Path, required=True)
args = parser.parse_args()

user32 = ctypes.WinDLL("user32", use_last_error=True)
user32.SetProcessDPIAware()
user32.GetAncestor.argtypes = [wintypes.HWND, wintypes.UINT]
user32.GetAncestor.restype = wintypes.HWND
user32.GetForegroundWindow.restype = wintypes.HWND
user32.GetWindowLongW.argtypes = [wintypes.HWND, ctypes.c_int]
user32.GetWindowLongW.restype = ctypes.c_long
user32.SetWindowLongW.argtypes = [wintypes.HWND, ctypes.c_int, ctypes.c_long]
user32.SetWindowDisplayAffinity.argtypes = [wintypes.HWND, wintypes.DWORD]
user32.GetWindowDisplayAffinity.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
user32.SetWindowPos.argtypes = [wintypes.HWND, wintypes.HWND, ctypes.c_int, ctypes.c_int,
                              ctypes.c_int, ctypes.c_int, wintypes.UINT]
user32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
user32.ClientToScreen.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.POINT)]
user32.IsIconic.argtypes = [wintypes.HWND]
user32.IsWindow.argtypes = [wintypes.HWND]
user32.IsWindowVisible.argtypes = [wintypes.HWND]
user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
CALLBACK = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
user32.EnumWindows.argtypes = [CALLBACK, wintypes.LPARAM]


def find_window():
    found = []
    @CALLBACK
    def visit(hwnd, _):
        pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        if pid.value == args.pid and user32.IsWindowVisible(hwnd):
            rect = wintypes.RECT()
            user32.GetClientRect(hwnd, ctypes.byref(rect))
            if rect.right > 300 and rect.bottom > 200:
                found.append(hwnd)
        return True
    user32.EnumWindows(visit, 0)
    return found[0] if found else None


root = tk.Tk()
root.withdraw()
root.overrideredirect(True)
root.attributes("-topmost", True)
root.attributes("-transparentcolor", "#000000")
canvas = tk.Canvas(root, bg="#000000", highlightthickness=0)
canvas.pack(fill="both", expand=True)
root.update_idletasks()
root.update()
hwnd = user32.GetAncestor(root.winfo_id(), 2)
style = user32.GetWindowLongW(hwnd, -20)
# Layered, click-through, tool window, no activation.
user32.SetWindowLongW(hwnd, -20, style | 0x80000 | 0x20 | 0x80 | 0x08000000)
if not user32.SetWindowDisplayAffinity(hwnd, 0x11):
    raise ctypes.WinError(ctypes.get_last_error())
affinity = wintypes.DWORD()
if not user32.GetWindowDisplayAffinity(hwnd, ctypes.byref(affinity)) or affinity.value != 0x11:
    raise RuntimeError("Display capture exclusion was not applied")

token = secrets.token_urlsafe(32)
lock = threading.Lock()
state = {"shapes": [], "updated": 0.0}
status = {"captureExcluded": True, "affinity": affinity.value, "pid": args.pid,
          "windowFound": bool(find_window()), "frameCount": 0, "redrawCount": 0}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def respond(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def authorized(self):
        if not secrets.compare_digest(self.headers.get("Authorization", ""), "Bearer " + token):
            self.respond(403, {"error": "Unauthorized"})
            return False
        return True

    def do_GET(self):
        if not self.authorized():
            return
        if self.path == "/status":
            self.respond(200, status)
        else:
            self.respond(404, {"error": "Not found"})

    def do_POST(self):
        if not self.authorized():
            return
        if self.path != "/frame":
            self.respond(404, {"error": "Not found"})
            return
        length = int(self.headers.get("Content-Length", "0"))
        if length < 2 or length > 1024 * 1024:
            self.respond(413, {"error": "Invalid frame size"})
            return
        try:
            frame = json.loads(self.rfile.read(length))
            shapes = frame["shapes"]
            if not isinstance(shapes, list) or len(shapes) > 2000:
                raise ValueError("Invalid shapes")
            with lock:
                state["shapes"] = shapes
                state["updated"] = time.monotonic()
                status["frameCount"] += 1
            self.respond(200, {"ok": True})
        except (ValueError, KeyError, TypeError):
            self.respond(400, {"error": "Invalid frame"})

    def do_DELETE(self):
        if not self.authorized():
            return
        with lock:
            state["shapes"] = []
            state["updated"] = 0.0
        self.respond(200, {"ok": True})


server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
args.config.parent.mkdir(parents=True, exist_ok=True)
args.config.write_text(json.dumps({"url": f"http://127.0.0.1:{args.port}", "token": token}), encoding="utf-8")
print(json.dumps(status), flush=True)
shown = False
last_shapes = None
last_geometry = None
cached_target = None
last_window_check = 0.0


def paint():
    global shown, last_shapes, last_geometry, cached_target, last_window_check
    now = time.monotonic()
    if now - last_window_check >= 0.5 or (cached_target and not user32.IsWindow(cached_target)):
        cached_target = find_window()
        last_window_check = now
    target = cached_target
    status["windowFound"] = bool(target)
    with lock:
        shapes = state["shapes"] if time.monotonic() - state["updated"] < 1.0 else []
    active = target and not user32.IsIconic(target) and user32.GetForegroundWindow() == target and shapes
    if active:
        rect, point = wintypes.RECT(), wintypes.POINT()
        user32.GetClientRect(target, ctypes.byref(rect))
        user32.ClientToScreen(target, ctypes.byref(point))
        if not shown:
            root.deiconify()
            shown = True
            last_geometry = None
        geometry = (point.x, point.y, rect.right, rect.bottom)
        if geometry != last_geometry:
            user32.SetWindowPos(hwnd, ctypes.c_void_p(-1), *geometry, 0x0010)
            last_geometry = geometry
        if shapes == last_shapes:
            root.after(16, paint)
            return
        last_shapes = shapes
        status["redrawCount"] += 1
        canvas.delete("all")
        for shape in sorted(shapes, key=lambda item: item.get("z", 1)):
            try:
                x, y = shape["p"]
                color = "#" + shape["color"]
                if shape["kind"] == "Square":
                    width, height = shape["s"]
                    canvas.create_rectangle(x, y, x + width, y + height, fill=color, outline="")
                elif shape["kind"] == "Circle":
                    radius = max(1, min(64, shape["radius"]))
                    canvas.create_oval(x-radius, y-radius, x+radius, y+radius, outline=color,
                                       width=max(1, min(8, shape.get("thickness", 1))))
                elif shape["kind"] == "Text":
                    text, size = shape["text"], shape["size"]
                    canvas.create_text(x + 1, y + 1, text=text, fill="#010101", anchor="nw",
                                       font=("Consolas", -int(size)))
                    canvas.create_text(x, y, text=text, fill=color, anchor="nw",
                                       font=("Consolas", -int(size)))
            except (KeyError, TypeError, ValueError, tk.TclError):
                continue
    elif shown:
        root.withdraw()
        shown = False
    root.after(16, paint)


root.after(16, paint)
try:
    root.mainloop()
finally:
    server.shutdown()
