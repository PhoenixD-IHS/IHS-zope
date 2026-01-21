#!/usr/local/bin/python
import sys
from urllib.error import HTTPError
from urllib.request import Request, urlopen

try:
    with urlopen(Request("http://localhest:8080"), timeout=4) as response:
        sys.exit(0 if response.status < 500 else 1)
except HTTPError as e:
    sys.exit(0 if e.code < 500 else 1)
except Exception:
    sys.exit(1)
