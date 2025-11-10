import logging
import os
from pathlib import Path


def setup_logger(base_dir: str) -> logging.Logger:
    logs_dir = Path(base_dir) / "data" / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger("fwgp")
    logger.setLevel(logging.INFO)

    # Avoid duplicate handlers in interactive sessions
    if logger.handlers:
        return logger

    fmt = logging.Formatter(
        fmt="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    ch = logging.StreamHandler()
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    fh = logging.FileHandler(logs_dir / "app.log", encoding="utf-8")
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    logger.info("Logger initialized. Base dir=%s", os.path.abspath(base_dir))
    return logger

